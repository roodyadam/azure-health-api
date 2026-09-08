const { app } = require('@azure/functions');

app.http('health', {
  methods: ['GET'],
  authLevel: 'anonymous',
  route: 'health',
  handler: async (request, context) => {
    return {
      jsonBody: {
        status: 'healthy',
        environment: process.env.ENVIRONMENT || 'dev'
      }
    };
  }
});