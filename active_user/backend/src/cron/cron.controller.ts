import { Controller, Get } from '@nestjs/common';

@Controller('cron')
export class CronController {
  
  @Get('ping')
  ping() {
    return {
      status: 'ok',
      message: 'Server is awake and internal cron jobs are active.',
      timestamp: new Date().toISOString(),
    };
  }
}
