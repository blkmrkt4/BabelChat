import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const HMS_ACCESS_KEY = Deno.env.get("HMS_ACCESS_KEY") || "";
const HMS_SECRET = Deno.env.get("HMS_SECRET") || "";

// Create a 100ms auth token (HS256 JWT)
async function createHMSToken(
  roomId: string,
  userId: string,
  role: string
): Promise<string> {
  const header = {
    alg: "HS256",
    typ: "JWT",
  };

  const now = Math.floor(Date.now() / 1000);
  const jti = crypto.randomUUID();

  const payload = {
    access_key: HMS_ACCESS_KEY,
    room_id: roomId,
    user_id: userId,
    role: role,
    type: "app",
    version: 2,
    iat: now,
    nbf: now,
    exp: now + 86400, // 24 hours
    jti: jti,
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
    encoder.encode(HMS_SECRET),
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

// Map SessionRole to 100ms role name
function mapRole(dbRole: string): string {
  switch (dbRole) {
    case "host":
      return "host";
    case "co_host":
      return "co_host";
    case "rotating_speaker":
      return "rotating_speaker";
    case "listener":
      return "listener";
    default:
      return "listener";
  }
}

serve(async (req) => {
  try {
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

    // Authenticate the caller
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser();

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

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Look up session
    const { data: session, error: sessionError } = await supabase
      .from("sessions")
      .select("id, livekit_room_name, hms_room_id, status")
      .eq("id", sessionId)
      .single();

    if (sessionError || !session) {
      return new Response(
        JSON.stringify({ error: "Session not found" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    if (!["live", "scheduled"].includes(session.status)) {
      return new Response(
        JSON.stringify({ error: "Session is no longer active" }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    // Look up participant role
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

    const hmsRoomId = session.hms_room_id;
    if (!hmsRoomId) {
      return new Response(
        JSON.stringify({ error: "Room not created yet" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const roomName = session.livekit_room_name || `session_${sessionId}`;
    const hmsRole = mapRole(participant.role);

    const token = await createHMSToken(hmsRoomId, userId, hmsRole);

    return new Response(
      JSON.stringify({
        token,
        roomName,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
