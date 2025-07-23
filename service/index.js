/* eslint-env node */

'use strict'

// Import tracing first if available
try {
  require('./tracer')
} catch (err) {
  // Tracing is optional for development
}

const {
  PDS,
  envToCfg,
  envToSecrets,
  readEnv,
  httpLogger,
} = require('@atproto/pds')
const pkg = require('@atproto/pds/package.json')

const main = async () => {
  try {
    const env = readEnv()
    env.version ??= pkg.version
    
    const cfg = envToCfg(env)
    const secrets = envToSecrets(env)
    
    httpLogger.info('Starting PDS with configuration', {
      hostname: cfg.service?.hostname,
      port: cfg.service?.port || process.env.PDS_PORT || 3000,
      nodeEnv: process.env.NODE_ENV
    })
    
    const pds = await PDS.create(cfg, secrets)

    // Add custom health check endpoint
    pds.app.get('/health', (req, res) => {
      res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        version: pkg.version,
        uptime: process.uptime()
      })
    })

    // Add custom TLS check endpoint (existing functionality)
    pds.app.get('/tls-check', (req, res) => {
      checkHandleRoute(pds, req, res)
    })

    await pds.start()
    httpLogger.info('PDS started successfully')

    // Enhanced graceful shutdown handling
    const shutdown = async (signal) => {
      httpLogger.info(`Received ${signal}, initiating graceful shutdown`)
      try {
        await pds.destroy()
        httpLogger.info('PDS shutdown completed successfully')
        process.exit(0)
      } catch (err) {
        httpLogger.error({ err }, 'Error during shutdown')
        process.exit(1)
      }
    }

    process.on('SIGTERM', () => shutdown('SIGTERM'))
    process.on('SIGINT', () => shutdown('SIGINT'))
    process.on('SIGHUP', () => shutdown('SIGHUP'))

    // Handle uncaught exceptions
    process.on('uncaughtException', (err) => {
      httpLogger.error({ err }, 'Uncaught exception, shutting down')
      shutdown('uncaughtException')
    })

    process.on('unhandledRejection', (reason, promise) => {
      httpLogger.error({ reason, promise }, 'Unhandled rejection, shutting down')
      shutdown('unhandledRejection')
    })

  } catch (error) {
    httpLogger.error({ err: error }, 'Failed to start PDS')
    process.exit(1)
  }
}

async function checkHandleRoute(
  /** @type {PDS} */ pds,
  /** @type {import('express').Request} */ req,
  /** @type {import('express').Response} */ res
) {
  const startTime = Date.now()
  
  try {
    const { domain } = req.query
    
    if (!domain || typeof domain !== 'string') {
      httpLogger.warn({ query: req.query }, 'TLS check: invalid domain parameter')
      return res.status(400).json({
        error: 'InvalidRequest',
        message: 'bad or missing domain query param',
      })
    }
    
    // Log the check attempt
    httpLogger.debug({ domain }, 'TLS check requested')
    
    if (domain === pds.ctx.cfg.service.hostname) {
      httpLogger.debug({ domain }, 'TLS check: matched service hostname')
      return res.json({ success: true, matched: 'service' })
    }
    
    const isHostedHandle = pds.ctx.cfg.identity.serviceHandleDomains.find(
      (avail) => domain.endsWith(avail)
    )
    
    if (!isHostedHandle) {
      httpLogger.debug({ domain, serviceHandleDomains: pds.ctx.cfg.identity.serviceHandleDomains }, 'TLS check: domain not in service handle domains')
      return res.status(400).json({
        error: 'InvalidRequest',
        message: 'handles are not provided on this domain',
      })
    }
    
    const account = await pds.ctx.accountManager.getAccount(domain)
    
    if (!account) {
      httpLogger.debug({ domain }, 'TLS check: handle not found')
      return res.status(404).json({
        error: 'NotFound',
        message: 'handle not found for this domain',
      })
    }
    
    const duration = Date.now() - startTime
    httpLogger.debug({ domain, duration }, 'TLS check: successful')
    
    return res.json({ success: true, matched: 'handle' })
    
  } catch (err) {
    const duration = Date.now() - startTime
    httpLogger.error({ err, domain: req.query?.domain, duration }, 'TLS check failed')
    
    return res.status(500).json({
      error: 'InternalServerError',
      message: 'Internal Server Error',
    })
  }
}

main();
