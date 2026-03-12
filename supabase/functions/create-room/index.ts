import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const HMS_ACCESS_KEY = Deno.env.get("HMS_ACCESS_KEY") || "";
const HMS_SECRET = Deno.env.get("HMS_SECRET") || "";
const HMS_TEMPLATE_ID = "69b315946236da36a7d8d4d9";

// Create a management token for 100ms API calls
async function createManagementToken(): Promise<string> {
  const header = { alg: "HS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);

  const payload = {
    access_key: HMS_ACCESS_KEY,
    type: "management",
    version: 2,
    iat: now,
    nbf: now,
    exp: now + 86400,
    jti: crypto.randomUUID(),
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

// Map host location string (e.g. "Toronto, Canada") to nearest 100ms region.
// 100ms regions: us2 (US East), eu (Europe), in (India), au (Australia)
function mapLocationToRegion(location: string): string {
  const loc = location.toLowerCase();

  // Asia-Pacific (India/South Asia)
  const india = ["india", "sri lanka", "bangladesh", "nepal", "pakistan", "mumbai", "delhi", "bangalore", "chennai", "kolkata", "hyderabad"];
  if (india.some((k) => loc.includes(k))) return "in";

  // Asia-Pacific (Australia/Oceania/Southeast Asia)
  const apac = ["australia", "new zealand", "indonesia", "singapore", "malaysia", "thailand", "vietnam", "philippines", "japan", "korea", "china", "taiwan", "hong kong", "sydney", "melbourne", "tokyo", "seoul", "beijing", "shanghai"];
  if (apac.some((k) => loc.includes(k))) return "au";

  // Europe / Middle East / Africa
  const europe = [
    "united kingdom", "uk", "england", "france", "germany", "spain", "italy",
    "netherlands", "belgium", "sweden", "norway", "denmark", "finland", "poland",
    "portugal", "switzerland", "austria", "ireland", "greece", "turkey", "russia",
    "ukraine", "czech", "romania", "hungary", "israel", "saudi", "emirates", "uae",
    "dubai", "qatar", "egypt", "south africa", "nigeria", "kenya", "morocco",
    "london", "paris", "berlin", "madrid", "amsterdam", "stockholm", "oslo",
    "copenhagen", "helsinki", "warsaw", "lisbon", "zurich", "vienna", "dublin",
    "rome", "barcelona", "munich", "prague", "budapest", "bucharest",
  ];
  if (europe.some((k) => loc.includes(k))) return "eu";

  // Americas (default) — US, Canada, Mexico, Central/South America
  return "us2";
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

    const { roomName, hostLocation } = await req.json();

    if (!roomName) {
      return new Response(
        JSON.stringify({ error: "roomName is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const region = mapLocationToRegion(hostLocation || "");

    // Create a management token
    const mgmtToken = await createManagementToken();

    // Create room via 100ms Management API
    const hmsResponse = await fetch("https://api.100ms.live/v2/rooms", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${mgmtToken}`,
      },
      body: JSON.stringify({
        name: roomName,
        template_id: HMS_TEMPLATE_ID,
        region,
      }),
    });

    if (!hmsResponse.ok) {
      const errorBody = await hmsResponse.text();
      console.error("100ms room creation failed:", errorBody);
      return new Response(
        JSON.stringify({ error: "Failed to create room", details: errorBody }),
        { status: 502, headers: { "Content-Type": "application/json" } }
      );
    }

    const room = await hmsResponse.json();

    return new Response(
      JSON.stringify({
        roomId: room.id,
        roomName: room.name,
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
