/**
 * 市场行情数据模型
 * 用于存储和更新投资品种的实时市场行情数据
 */

/**
 * 市场行情数据模型
 */
export class MarketQuoteModel {
  /**
   * 行情ID
   */
  id?: number;
  
  /**
   * 股票/基金代码
   */
  code: string;
  
  /**
   * 股票/基金名称
   */
  name: string;
  
  /**
   * 当前价格
   */
  currentPrice: number;
  
  /**
   * 涨跌额
   */
  changeAmount: number;
  
  /**
   * 涨跌幅（百分比）
   */
  changePercent: number;
  
  /**
   * 开盘价
   */
  openPrice: number;
  
  /**
   * 最高价
   */
  highPrice: number;
  
  /**
   * 最低价
   */
  lowPrice: number;
  
  /**
   * 收盘价（上一交易日）
   */
  closePrice: number;
  
  /**
   * 成交量
   */
  volume: number;
  
  /**
   * 成交额
   */
  turnover: number;
  
  /**
   * 更新时间
   */
  updateTime: number;
  
  /**
   * 数据来源
   */
  source: string;
  
  constructor(
    code: string,
    name: string,
    currentPrice: number,
    changeAmount: number = 0,
    changePercent: number = 0,
    openPrice: number = 0,
    highPrice: number = 0,
    lowPrice: number = 0,
    closePrice: number = 0,
    volume: number = 0,
    turnover: number = 0,
    source: string = '',
    id?: number
  ) {
    this.id = id;
    this.code = code;
    this.name = name;
    this.currentPrice = currentPrice;
    this.changeAmount = changeAmount;
    this.changePercent = changePercent;
    this.openPrice = openPrice;
    this.highPrice = highPrice;
    this.lowPrice = lowPrice;
    this.closePrice = closePrice;
    this.volume = volume;
    this.turnover = turnover;
    this.source = source;
    this.updateTime = new Date().getTime();
  }
  
  /**
   * 判断当前股票是否上涨
   * @returns 是否上涨
   */
  isUp(): boolean {
    return this.changeAmount > 0;
  }
  
  /**
   * 判断当前股票是否下跌
   * @returns 是否下跌
   */
  isDown(): boolean {
    return this.changeAmount < 0;
  }
  
  /**
   * 格式化涨跌幅
   * @returns 格式化后的涨跌幅字符串
   */
  formatChangePercent(): string {
    const prefix = this.isUp() ? '+' : '';
    return `${prefix}${this.changePercent.toFixed(2)}%`;
  }
  
  /**
   * 更新行情数据
   * @param newData 新的行情数据
   */
  updateQuote(newData: IQuoteUpdateParams): void {
    if (newData.currentPrice !== undefined) {
      this.currentPrice = newData.currentPrice;
    }
    if (newData.changeAmount !== undefined) {
      this.changeAmount = newData.changeAmount;
    }
    if (newData.changePercent !== undefined) {
      this.changePercent = newData.changePercent;
    }
    if (newData.openPrice !== undefined) {
      this.openPrice = newData.openPrice;
    }
    if (newData.highPrice !== undefined) {
      this.highPrice = newData.highPrice;
    }
    if (newData.lowPrice !== undefined) {
      this.lowPrice = newData.lowPrice;
    }
    if (newData.closePrice !== undefined) {
      this.closePrice = newData.closePrice;
    }
    if (newData.volume !== undefined) {
      this.volume = newData.volume;
    }
    if (newData.turnover !== undefined) {
      this.turnover = newData.turnover;
    }
    
    this.updateTime = new Date().getTime();
  }
  
  /**
   * 从API响应数据更新市场行情
   * @param apiData API响应数据
   * @returns 更新后的行情模型
   */
  static fromApiData(apiData: IMarketQuoteApiData): MarketQuoteModel {
    return new MarketQuoteModel(
      apiData.code || '',
      apiData.name || '',
      parseFloat(apiData.price.toString()) || 0,
      parseFloat(apiData.change.toString()) || 0,
      parseFloat(apiData.percent.toString()) || 0,
      parseFloat(apiData.open.toString()) || 0,
      parseFloat(apiData.high.toString()) || 0,
      parseFloat(apiData.low.toString()) || 0,
      parseFloat(apiData.close.toString()) || 0,
      parseFloat(apiData.volume.toString()) || 0,
      parseFloat(apiData.amount.toString()) || 0,
      apiData.source || '',
      apiData.id
    );
  }
  
  /**
   * 从数据库记录转换为模型对象
   * @param record 数据库记录
   * @returns 市场行情模型对象
   */
  static fromRecord(record: IMarketQuoteRecord): MarketQuoteModel {
    return new MarketQuoteModel(
      record.code,
      record.name,
      record.currentPrice,
      record.changeAmount,
      record.changePercent,
      record.openPrice,
      record.highPrice,
      record.lowPrice,
      record.closePrice,
      record.volume,
      record.turnover,
      record.source,
      record.id
    );
  }
  
  /**
   * 判断行情数据是否过期
   * @param maxAgeMs 最大允许过期时间（毫秒）
   * @returns 是否过期
   */
  isExpired(maxAgeMs: number): boolean {
    const now = new Date().getTime();
    return now - this.updateTime > maxAgeMs;
  }
}

/**
 * u5e02u573au884cu60c5u6570u636eu5e93u8bb0u5f55u63a5u53e3
 */
export interface IMarketQuoteRecord {
  id?: number;
  code: string;
  name: string;
  currentPrice: number;
  changeAmount: number;
  changePercent: number;
  openPrice: number;
  highPrice: number;
  lowPrice: number;
  closePrice: number;
  volume: number;
  turnover: number;
  source: string;
  updateTime?: number;
}

/**
 * APIu8fd4u56deu7684u884cu60c5u6570u636eu63a5u53e3
 */
export interface IMarketQuoteApiData {
  id?: number;
  code: string;
  name: string;
  price: string | number;
  change: string | number;
  percent: string | number;
  open: string | number;
  high: string | number;
  low: string | number;
  close: string | number;
  volume: string | number;
  amount: string | number;
  source?: string;
}

/**
 * 更新行情数据参数接口
 */
export interface IQuoteUpdateParams {
  currentPrice?: number;
  changeAmount?: number;
  changePercent?: number;
  openPrice?: number;
  highPrice?: number;
  lowPrice?: number;
  closePrice?: number;
  volume?: number;
  turnover?: number;
}
