import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const LIVEKIT_API_KEY = Deno.env.get("LIVEKIT_API_KEY") || "";
const LIVEKIT_API_SECRET = Deno.env.get("LIVEKIT_API_SECRET") || "";
const LIVEKIT_URL = Deno.env.get("LIVEKIT_URL") || "";

// Simple JWT creation for LiveKit tokens
async function createLiveKitToken(
  roomName: string,
  participantIdentity: string,
  canPublish: boolean,
  canSubscribe: boolean
): Promise<string> {
  const header = {
    alg: "HS256",
    typ: "JWT",
  };

  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: LIVEKIT_API_KEY,
    sub: participantIdentity,
    iat: now,
    nbf: now,
    exp: now + 3600, // 1 hour
    video: {
      roomJoin: true,
      room: roomName,
      canPublish,
      canSubscribe,
      canPublishData: true,
    },
  };

  const encoder = new TextEncoder();

  const headerB64 = btoa(JSON.stringify(header))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
  const payloadB64 = btoa(JSON.stringify(payload))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const data = encoder.encode(`${headerB64}.${payloadB64}`);
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(LIVEKIT_API_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign("HMAC", key, data);
  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  return `${headerB64}.${payloadB64}.${signatureB64}`;
}

serve(async (req) => {
  try {
    // Derive userId from the authenticated Supabase JWT — not from the request body
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "Missing or invalid Authorization header" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") || "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

    // Create a client with the user's JWT to extract their identity
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: authError } = await userClient.auth.getUser();

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Authentication failed" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const userId = user.id;
    const { sessionId } = await req.json();

    if (!sessionId) {
      return new Response(
        JSON.stringify({ error: "sessionId is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Create Supabase client with service role for DB access
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Look up session and participant role
    const { data: session, error: sessionError } = await supabase
      .from("sessions")
      .select("id, livekit_room_name, status")
      .eq("id", sessionId)
      .single();

    if (sessionError || !session) {
      return new Response(
        JSON.stringify({ error: "Session not found" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    // Guard: only issue tokens for active sessions
    if (!["live", "scheduled"].includes(session.status)) {
      return new Response(
        JSON.stringify({ error: "Session is no longer active" }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data: participant, error: participantError } = await supabase
      .from("session_participants")
      .select("role, is_active")
      .eq("session_id", sessionId)
      .eq("user_id", userId)
      .single();

    if (participantError || !participant || !participant.is_active) {
      return new Response(
        JSON.stringify({ error: "Not an active participant" }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    // Speakers can publish, listeners can only subscribe
    const canPublish = ["host", "co_speaker", "rotating_speaker"].includes(
      participant.role
    );

    const roomName =
      session.livekit_room_name || `session_${sessionId}`;

    const token = await createLiveKitToken(
      roomName,
      userId,
      canPublish,
      true // everyone can subscribe
    );

    return new Response(
      JSON.stringify({
        token,
        roomName,
        url: LIVEKIT_URL,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
