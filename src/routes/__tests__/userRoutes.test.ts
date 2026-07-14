/**
 * Copyright (c) 2021-2026 Red Hat, Inc.
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 *
 * Contributors:
 *   Red Hat, Inc. - initial API and implementation
 */

import Fastify, { FastifyInstance } from 'fastify';
import { registerUserRoutes } from '../userRoutes';
import { authenticate, requireAuth } from '../../middleware/auth';

describe('User Routes', () => {
  let app: FastifyInstance;

  beforeEach(async () => {
    app = Fastify();
    app.decorate('authenticate', authenticate);
    app.decorate('requireAuth', requireAuth);
    await registerUserRoutes(app);
    await app.ready();
  });

  afterEach(async () => {
    await app.close();
  });

  describe('GET /user', () => {
    it('returns name and email for authenticated user', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/user',
        headers: {
          Authorization: 'Bearer user123:johndoe',
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body).toHaveProperty('name');
      expect(body).toHaveProperty('email');
      expect(typeof body.name).toBe('string');
      expect(body.email).toBe(`${body.name}@che`);
    });

    it('returns 401 when unauthenticated', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/user',
      });

      expect(response.statusCode).toBe(401);
    });
  });

  describe('GET /user/id', () => {
    it('returns id and name for authenticated user', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/user/id',
        headers: {
          Authorization: 'Bearer user123:johndoe',
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body).toHaveProperty('id');
      expect(body).toHaveProperty('name');
    });

    it('returns 401 when unauthenticated', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/user/id',
      });

      expect(response.statusCode).toBe(401);
    });
  });
});
