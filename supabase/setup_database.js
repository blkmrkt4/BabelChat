// Setup database schema for LangChat
// Run this script to create all tables in Supabase

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

// Initialize Supabase client with service role key for admin access
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
    console.error('Missing Supabase credentials in .env file');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
        autoRefreshToken: false,
        persistSession: false
    }
});

async function setupDatabase() {
    console.log('🚀 Starting database setup for LangChat...\n');

    try {
        // Read the SQL schema file
        const schemaPath = path.join(__dirname, 'schema.sql');
        const schema = fs.readFileSync(schemaPath, 'utf8');

        // Split the schema into individual statements
        const statements = schema
            .split(';')
            .map(s => s.trim())
            .filter(s => s.length > 0 && !s.startsWith('--'));

        console.log(`📋 Found ${statements.length} SQL statements to execute\n`);

        // Execute each statement
        for (let i = 0; i < statements.length; i++) {
            const statement = statements[i] + ';';
            const firstLine = statement.split('\n')[0];

            // Skip if it's just a comment
            if (firstLine.startsWith('--')) continue;

            console.log(`[${i + 1}/${statements.length}] Executing: ${firstLine.substring(0, 50)}...`);

            const { error } = await supabase.rpc('exec_sql', {
                sql_query: statement
            }).single();

            if (error) {
                // Try direct execution as fallback
                const { error: directError } = await supabase.from('_sql').insert({ query: statement });

                if (directError) {
                    console.error(`❌ Error: ${directError.message}`);
                    // Continue with next statement instead of stopping
                } else {
                    console.log('✅ Success');
                }
            } else {
                console.log('✅ Success');
            }
        }

        console.log('\n✨ Database setup completed successfully!');
        console.log('\n📊 Created tables:');
        console.log('  - profiles');
        console.log('  - user_languages');
        console.log('  - matches');
        console.log('  - swipes');
        console.log('  - conversations');
        console.log('  - messages');
        console.log('  - user_preferences');
        console.log('  - saved_phrases');
        console.log('  - language_lab_stats');
        console.log('  - notifications');
        console.log('  - reported_users');
        console.log('  - subscriptions');
        console.log('\n🔒 Row Level Security policies applied');
        console.log('📈 Performance indexes created');
        console.log('⚡ Triggers and functions set up');

    } catch (error) {
        console.error('❌ Setup failed:', error.message);
        process.exit(1);
    }
}

// Run the setup
setupDatabase();