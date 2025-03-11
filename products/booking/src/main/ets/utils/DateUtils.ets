/**
 * 日期工具类
 */

import dayjs from 'dayjs';

// 时间范围接口
interface TimeRange {
  startTime: number;
  endTime: number;
}

export { TimeRange };

export class DateUtils {
  /**
   * 格式化日期
   * @param timestamp 时间戳或日期对象
   * @param fmt 格式
   * @returns 格式化后的字符串
   */
  static formatDate(timestamp: number | Date, fmt: string = 'YYYY-MM-DD'): string {
    const date = timestamp instanceof Date ? timestamp : new Date(timestamp);
    return dayjs(date).format(fmt);
  }

  /**
   * 获取当前月份的文本表示
   * @returns 当前月份的文本表示
   */
  static getCurrentMonthText(): string {
    const now = new Date();
    return DateUtils.formatDate(now.getTime(), 'YYYY年MM月');
  }

  /**
   * 获取当前月份的字符串表示
   * @param date 可选的日期参数，默认为当前日期
   * @returns 当前月份的字符串表示
   */
  static getCurrentMonthStr(date?: Date): string {
    const targetDate = date || new Date();
    return DateUtils.formatDate(targetDate.getTime(), 'YYYY年MM月');
  }

  /**
   * 获取当前月份的开始和结束时间戳
   * @returns 开始和结束时间戳
   */
  static getCurrentMonthTimeRange(): TimeRange {
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth();

    const start = new Date(year, month, 1);
    const end = new Date(year, month + 1, 0, 23, 59, 59, 999);

    return {
      startTime: start.getTime(),
      endTime: end.getTime()
    };
  }

  /**
   * 获取某个日期范围的开始和结束时间戳
   * @param year 年份
   * @param month 月份(0-11)
   * @returns 开始和结束时间戳
   */
  static getMonthRange(year: number, month: number): TimeRange {
    const start = new Date(year, month, 1);
    const end = new Date(year, month + 1, 0, 23, 59, 59, 999);

    return {
      startTime: start.getTime(),
      endTime: end.getTime()
    };
  }

  /**
   * 获取日期的字符串表示
   * @param timestamp 时间戳
   * @returns 格式化后的字符串
   */
  static getDateStr(timestamp: number): string {
    return DateUtils.formatDate(timestamp, 'YYYY-MM-DD');
  }

  /**
   * 获取最近几个月的时间范围
   * @param months 月数
   * @returns 开始和结束时间戳
   */
  static getRecentMonthsRange(months: number): TimeRange {
    const now = new Date();
    const end = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
    const start = new Date(now.getFullYear(), now.getMonth() - months + 1, 1);

    return {
      startTime: start.getTime(),
      endTime: end.getTime()
    };
  }
}
