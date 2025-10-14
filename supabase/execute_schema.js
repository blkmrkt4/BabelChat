#!/usr/bin/env node

/**
 * Execute Supabase database schema
 * This script runs all SQL migration files in order
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ Error: Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env file');
  process.exit(1);
}

// SQL files to execute in order
const sqlFiles = [
  '01_extensions_and_tables.sql',
  '02_messaging_tables.sql',
  '03_stats_and_admin_tables.sql',
  '04_indexes.sql',
  '05_rls_policies.sql',
  '06_functions_and_triggers.sql'
];

/**
 * Execute SQL query using Supabase REST API
 */
async function executeSql(sql, filename) {
  return new Promise((resolve, reject) => {
    const url = new URL('/rest/v1/rpc/exec_sql', SUPABASE_URL);

    const postData = JSON.stringify({ query: sql });

    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(url, options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ success: true, data });
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

/**
 * Execute SQL file directly using pg connection string
 */
async function executeSqlFile(filename) {
  const filePath = path.join(__dirname, filename);

  if (!fs.existsSync(filePath)) {
    throw new Error(`File not found: ${filePath}`);
  }

  const sql = fs.readFileSync(filePath, 'utf8');

  console.log(`\n📄 Executing ${filename}...`);
  console.log(`   Lines: ${sql.split('\n').length}`);

  // Use curl to execute SQL via Supabase's SQL editor endpoint
  const { execSync } = require('child_process');

  try {
    // Create a temporary file with the SQL
    const tempFile = path.join(__dirname, 'temp_query.sql');
    fs.writeFileSync(tempFile, sql);

    // Note: This approach requires the Supabase CLI or direct database access
    // For now, we'll output instructions for manual execution
    console.log(`   ⚠️  Please execute this file manually in Supabase SQL Editor:`);
    console.log(`   📍 https://supabase.com/dashboard/project/ckhukylfoeofvoxvwwin/sql`);

    return { success: true };
  } catch (error) {
    throw new Error(`Failed to execute ${filename}: ${error.message}`);
  }
}

/**
 * Main execution
 */
async function main() {
  console.log('🚀 LangChat Database Setup\n');
  console.log(`📍 Supabase URL: ${SUPABASE_URL}`);
  console.log(`🔑 Using service role key: ${SUPABASE_SERVICE_ROLE_KEY.substring(0, 20)}...`);

  console.log('\n⚠️  IMPORTANT: SQL execution via REST API is limited.');
  console.log('The recommended approach is to execute these files manually in the Supabase SQL Editor.\n');

  console.log('📋 Files to execute (in order):');
  sqlFiles.forEach((file, index) => {
    const filePath = path.join(__dirname, file);
    const exists = fs.existsSync(filePath);
    console.log(`   ${index + 1}. ${file} ${exists ? '✅' : '❌ NOT FOUND'}`);
  });

  console.log('\n🌐 Open Supabase SQL Editor:');
  console.log('   https://supabase.com/dashboard/project/ckhukylfoeofvoxvwwin/sql\n');

  console.log('📝 Then execute each file by copying and pasting its contents.\n');

  // Create a combined schema file for convenience
  console.log('📦 Creating combined schema file for easier execution...');
  const combinedPath = path.join(__dirname, 'combined_schema.sql');
  let combinedSql = '-- LangChat Complete Database Schema\n';
  combinedSql += '-- Generated: ' + new Date().toISOString() + '\n';
  combinedSql += '-- Execute this entire file in Supabase SQL Editor\n\n';

  sqlFiles.forEach((file) => {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
      combinedSql += `\n\n-- ====================================\n`;
      combinedSql += `-- ${file}\n`;
      combinedSql += `-- ====================================\n\n`;
      combinedSql += fs.readFileSync(filePath, 'utf8');
    }
  });

  fs.writeFileSync(combinedPath, combinedSql);
  console.log(`   ✅ Created: ${combinedPath}`);
  console.log(`   📊 Total lines: ${combinedSql.split('\n').length}`);

  console.log('\n✨ You can now execute the combined_schema.sql file in one go!');
  console.log('   Or execute individual files in the order listed above.\n');
}

main().catch((error) => {
  console.error('❌ Error:', error.message);
  process.exit(1);
});
