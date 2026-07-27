// Netlify serverless function — returns the Supabase connection info
// pulled from Netlify's environment variables at request time.
//
// This keeps the actual Supabase URL/key out of the GitHub repo entirely:
// they only live in Netlify's Site settings > Environment variables.
//
// The "anon public" key is meant to be exposed to the browser (it's the
// same key that would otherwise be hardcoded in index.html) -- access
// control still comes from the Row Level Security policies in schema.sql,
// not from hiding this key.

exports.handler = async function () {
  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
    body: JSON.stringify({
      url: process.env.SUPABASE_URL || "",
      anonKey: process.env.SUPABASE_ANON_KEY || "",
    }),
  };
};
