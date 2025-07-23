/* eslint-env node */
/* eslint-disable import/order */

'use strict'

// Optional tracing setup for production environments
// This file provides DataDog and OpenTelemetry instrumentation
// when the required packages are available

try {
  const { registerInstrumentations } = require('@opentelemetry/instrumentation')
  const {
    BetterSqlite3Instrumentation,
  } = require('opentelemetry-plugin-better-sqlite3')
  
  // Initialize DataDog tracer with log injection
  const { TracerProvider } = require('dd-trace')
    .init({ 
      logInjection: true,
      env: process.env.DD_ENV || process.env.NODE_ENV || 'development',
      service: process.env.DD_SERVICE || 'pds',
      version: process.env.DD_VERSION || require('@atproto/pds/package.json').version
    })
    .use('express', {
      hooks: { request: maintainXrpcResource },
    })

  const tracer = new TracerProvider()
  tracer.register()

  // Register OpenTelemetry instrumentations
  registerInstrumentations({
    tracerProvider: tracer,
    instrumentations: [
      new BetterSqlite3Instrumentation({
        // Add SQLite-specific tracing options
        collectParameters: process.env.NODE_ENV !== 'production'
      })
    ],
  })

  console.log('✓ Tracing initialized with DataDog and OpenTelemetry')

} catch (err) {
  // Tracing dependencies are optional
  if (process.env.NODE_ENV === 'production') {
    console.warn('⚠ Tracing dependencies not available:', err.message)
  } else {
    console.log('ℹ Tracing skipped in development (dependencies not installed)')
  }
}

const path = require('node:path')

/**
 * Maintain XRPC method name as the trace resource name
 * This provides better observability for AT Protocol operations
 */
function maintainXrpcResource(span, req) {
  // Show actual XRPC method as resource rather than the route pattern
  if (span && req.originalUrl?.startsWith('/xrpc/')) {
    span.setTag(
      'resource.name',
      [
        req.method,
        path.posix.join(req.baseUrl || '', req.path || '', '/').slice(0, -1), // Ensures no trailing slash
      ]
        .filter(Boolean)
        .join(' '),
    )
  }
}