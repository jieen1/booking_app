/**
 * 投资品种数据模型
 * 用于记录股票、基金等投资品种信息
 */
import { InvestmentType } from './InvestmentBookModel';

/**
 * 投资品种模型
 */
export class InvestmentAssetModel {
  /**
   * 投资品种ID
   */
  id?: number;
  
  /**
   * 所属投资账本ID
   */
  bookId: number;
  
  /**
   * 股票/基金代码
   */
  code: string;
  
  /**
   * 股票/基金名称
   */
  name: string;
  
  /**
   * 品种类型：1-股票, 2-基金, 3-债券, 999-其他
   */
  assetType: InvestmentType;
  
  /**
   * 购入价格（加权平均）
   */
  purchasePrice: number;
  
  /**
   * 当前价格
   */
  currentPrice: number;
  
  /**
   * 持有数量
   */
  quantity: number;
  
  /**
   * 持仓成本（购入价格 * 数量）
   */
  cost: number;
  
  /**
   * 当前市值（当前价格 * 数量）
   */
  marketValue: number;
  
  /**
   * 收益金额（市值 - 成本）
   */
  profit: number;
  
  /**
   * 收益率（百分比）
   */
  profitRate: number;
  
  /**
   * 最后更新时间
   */
  updateTime: number;
  
  /**
   * 创建时间
   */
  createTime: number;
  
  constructor(
    bookId: number, 
    code: string, 
    name: string, 
    assetType: InvestmentType, 
    purchasePrice: number, 
    currentPrice: number, 
    quantity: number,
    id?: number
  ) {
    this.id = id;
    this.bookId = bookId;
    this.code = code;
    this.name = name;
    this.assetType = assetType;
    this.purchasePrice = purchasePrice;
    this.currentPrice = currentPrice;
    this.quantity = quantity;
    
    // 计算相关衍生数据
    this.cost = parseFloat((purchasePrice * quantity).toFixed(2));
    this.marketValue = parseFloat((currentPrice * quantity).toFixed(2));
    this.profit = parseFloat((this.marketValue - this.cost).toFixed(2));
    this.profitRate = this.cost > 0 ? parseFloat(((this.profit / this.cost) * 100).toFixed(2)) : 0;
    
    this.updateTime = new Date().getTime();
    this.createTime = new Date().getTime();
  }
  
  /**
   * 更新当前价格
   * @param newPrice 新的当前价格
   */
  updateCurrentPrice(newPrice: number): void {
    this.currentPrice = newPrice;
    this.updateMarketValue();
  }
  
  /**
   * 更新持有数量
   * @param newQuantity 新的持有数量
   */
  updateQuantity(newQuantity: number): void {
    this.quantity = newQuantity;
    this.updateMarketValue();
  }
  
  /**
   * 更新市值和收益
   */
  private updateMarketValue(): void {
    this.marketValue = parseFloat((this.currentPrice * this.quantity).toFixed(2));
    this.profit = parseFloat((this.marketValue - this.cost).toFixed(2));
    this.profitRate = this.cost > 0 ? parseFloat(((this.profit / this.cost) * 100).toFixed(2)) : 0;
    this.updateTime = new Date().getTime();
  }
  
  /**
   * 获取当前价值
   * @returns 当前价值（最新价格 * 数量）
   */
  getCurrentValue(): number {
    return parseFloat((this.currentPrice * this.quantity).toFixed(2));
  }
  
  /**
   * 获取持仓成本
   * @returns 持仓成本（购入价格 * 数量）
   */
  getCost(): number {
    return parseFloat((this.purchasePrice * this.quantity).toFixed(2));
  }
  
  /**
   * 获取收益金额
   * @returns 收益金额（市值 - 成本）
   */
  getProfit(): number {
    return parseFloat((this.getCurrentValue() - this.getCost()).toFixed(2));
  }
  
  /**
   * 获取收益率
   * @returns 收益率（百分比）
   */
  getProfitRate(): number {
    if (this.getCost() === 0) {
      return 0;
    }
    return parseFloat(((this.getProfit() / this.getCost()) * 100).toFixed(2));
  }
  
  /**
   * 获取收益颜色
   * @returns 收益颜色（红色、绿色或灰色）
   */
  getProfitColor(): string {
    const profit = this.getProfit();
    if (profit > 0) {
      return '#E74C3C'; // 收益红色
    } else if (profit < 0) {
      return '#2ECC71'; // 亏损绿色
    } else {
      return '#333333'; // 持平灰色
    }
  }
  
  /**
   * 从数据库记录转换为模型对象
   * @param record 数据库记录
   * @returns 投资品种模型对象
   */
  static fromRecord(record: IInvestmentAssetRecord): InvestmentAssetModel {
    const asset = new InvestmentAssetModel(
      record.bookId,
      record.code,
      record.name,
      record.assetType,
      record.purchasePrice,
      record.currentPrice,
      record.quantity,
      record.id
    );
    
    // 添加类型保护，确保不会赋值undefined
    asset.cost = record.cost ?? 0;
    asset.marketValue = record.marketValue ?? 0;
    asset.profit = record.profit ?? 0;
    asset.profitRate = record.profitRate ?? 0;
    asset.updateTime = record.updateTime ?? Date.now();
    asset.createTime = record.createTime ?? Date.now();
    
    return asset;
  }
}

/**
 * 投资品种记录接口
 */
export interface IInvestmentAssetRecord {
  id?: number;
  bookId: number;
  code: string;
  name: string;
  assetType: InvestmentType;
  purchasePrice: number;
  currentPrice: number;
  quantity: number;
  cost?: number;
  marketValue?: number;
  profit?: number;
  profitRate?: number;
  updateTime?: number;
  createTime?: number;
}
