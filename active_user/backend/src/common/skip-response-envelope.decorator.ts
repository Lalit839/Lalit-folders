import { SetMetadata } from '@nestjs/common';

export const SKIP_RESPONSE_ENVELOPE = 'skipResponseEnvelope';

/** Marks a route handler so ApiEnvelopeInterceptor leaves its response un-wrapped (e.g. streaming media). */
export const SkipResponseEnvelope = () => SetMetadata(SKIP_RESPONSE_ENVELOPE, true);