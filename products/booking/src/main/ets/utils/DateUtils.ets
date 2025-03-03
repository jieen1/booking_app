/**
 * 日期工具类
 */

// 日期格式化选项接口
interface DateFormatOptions {
  'M+': number;
  'd+': number;
  'h+': number;
  'H+': number;
  'm+': number;
  's+': number;
  'q+': number;
  'S': number;
}

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
  static formatDate(timestamp: number | Date, fmt: string = 'yyyy-MM-dd'): string {
    const date = timestamp instanceof Date ? timestamp : new Date(timestamp);
    let format = fmt;
    
    if (/(y+)/.test(format)) {
      format = format.replace(RegExp.$1, (date.getFullYear() + '').substr(4 - RegExp.$1.length));
    }
    
    // 月份
    if (/(M+)/.test(format)) {
      const month = date.getMonth() + 1;
      format = format.replace(RegExp.$1, (RegExp.$1.length === 1) ? String(month) : 
                           (('00' + month).substr(('' + month).length)));
    }
    
    // 日
    if (/(d+)/.test(format)) {
      const day = date.getDate();
      format = format.replace(RegExp.$1, (RegExp.$1.length === 1) ? String(day) : 
                           (('00' + day).substr(('' + day).length)));
    }
    
    // 12小时制
    if (/(h+)/.test(format)) {
      const hour12 = date.getHours() % 12 === 0 ? 12 : date.getHours() % 12;
      format = format.replace(RegExp.$1, (RegExp.$1.length === 1) ? String(hour12) : 
                           (('00' + hour12).substr(('' + hour12).length)));
    }
    
    // 24小时制
    if (/(H+)/.test(format)) {
      const hour24 = date.getHours();
      format = format.replace(RegExp.$1, (RegExp.$1.length === 1) ? String(hour24) : 
                           (('00' + hour24).substr(('' + hour24).length)));
    }
    
    // 分钟
    if (/(m+)/.test(format)) {
      const minutes = date.getMinutes();
      format = format.replace(RegExp.$1, (RegExp.$1.length === 1) ? String(minutes) : 
                           (('00' + minutes).substr(('' + minutes).length)));
    }
    
    // 秒
    if (/(s+)/.test(format)) {
      const seconds = date.getSeconds();
      format = format.replace(RegExp.$1, (RegExp.$1.length === 1) ? String(seconds) : 
                           (('00' + seconds).substr(('' + seconds).length)));
    }
    
    // 季度
    if (/(q+)/.test(format)) {
      const quarter = Math.floor((date.getMonth() + 3) / 3);
      format = format.replace(RegExp.$1, (RegExp.$1.length === 1) ? String(quarter) : 
                           (('00' + quarter).substr(('' + quarter).length)));
    }
    
    // 毫秒
    if (/(S)/.test(format)) {
      const milliseconds = date.getMilliseconds();
      format = format.replace(RegExp.$1, (RegExp.$1.length === 1) ? String(milliseconds) : 
                           (('00' + milliseconds).substr(('' + milliseconds).length)));
    }
    
    return format;
  }

  /**
   * 获取当前月份的文本表示
   * @returns 当前月份的文本表示
   */
  static getCurrentMonthText(): string {
    const now = new Date();
    return DateUtils.formatDate(now.getTime(), 'yyyy年MM月');
  }

  /**
   * 获取当前月份的字符串表示
   * @param date 可选的日期参数，默认为当前日期
   * @returns 当前月份的字符串表示
   */
  static getCurrentMonthStr(date?: Date): string {
    const targetDate = date || new Date();
    return DateUtils.formatDate(targetDate.getTime(), 'yyyy年MM月');
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
    const date = new Date(timestamp);
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const yesterday = today - 86400000;
    
    const dateTime = new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
    
    if (dateTime === today) {
      return '今天';
    } else if (dateTime === yesterday) {
      return '昨天';
    } else {
      return DateUtils.formatDate(timestamp, 'MM-dd');
    }
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
