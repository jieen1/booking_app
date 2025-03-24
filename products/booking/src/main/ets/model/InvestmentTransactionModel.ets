/**
 * 投资交易记录数据模型
 */

/**
 * 交易类型枚举
 */
export enum TransactionType {
  BUY = 1,           // 买入
  SELL = 2,          // 卖出
  TRANSFER_OUT = 3,  // 转出
  TRANSFER_IN = 4    // 转入
}

/**
 * 投资交易记录数据库记录接口
 */
export interface IInvestmentTransactionRecord {
  id?: number;
  bookId: number;
  assetId: number;
  transactionType: TransactionType;
  price: number;
  quantity: number;
  amount: number;
  fee: number;
  tax: number;
  relatedAccountId: number;
  remarks: string;
  transactionTime: number;
  createTime: number;
}

/**
 * 投资交易记录模型
 */
export class InvestmentTransactionModel {
  /**
   * 交易记录ID
   */
  id?: number;
  
  /**
   * 所属投资账本ID
   */
  bookId: number;
  
  /**
   * 投资品种ID
   */
  assetId: number;
  
  /**
   * 交易类型：1-买入, 2-卖出, 3-转出, 4-转入
   */
  type: TransactionType;
  
  /**
   * 交易价格
   */
  price: number;
  
  /**
   * 交易数量
   */
  quantity: number;
  
  /**
   * 交易金额（价格 * 数量）
   */
  amount: number;
  
  /**
   * 交易费用
   */
  fee: number;
  
  /**
   * 税费
   */
  tax: number = 0;
  
  /**
   * 关联普通账本ID（资金来源/去向）
   */
  relatedAccountId: number;
  
  /**
   * 备注
   */
  remarks: string;
  
  /**
   * 交易时间
   */
  transactionTime: number;
  
  /**
   * 创建时间
   */
  createTime: number;
  
  constructor(
    bookId: number = 0,
    assetId: number = 0,
    type: TransactionType = TransactionType.BUY,
    price: number = 0,
    quantity: number = 0,
    amount: number = 0,
    fee: number = 0,
    relatedAccountId: number = 0,
    remarks: string = '',
    createTime: number = Date.now(),
    id?: number
  ) {
    this.id = id;
    this.bookId = bookId;
    this.assetId = assetId;
    this.type = type;
    this.price = price;
    this.quantity = quantity;
    this.amount = amount || parseFloat((price * quantity).toFixed(2));
    this.fee = fee;
    this.relatedAccountId = relatedAccountId;
    this.remarks = remarks;
    
    this.transactionTime = createTime;
    this.createTime = createTime || Date.now();
  }
  
  /**
   * 获取交易总成本（包含费用和税收）
   * @returns 总成本
   */
  getTotalCost(): number {
    if (this.type === TransactionType.BUY) {
      return this.amount + this.fee + this.tax;
    } else {
      return this.amount - this.fee - this.tax;
    }
  }
  
  /**
   * 从数据库记录转换为模型对象
   * @param record 数据库记录
   * @returns 投资交易记录模型对象
   */
  static fromRecord(record: IInvestmentTransactionRecord): InvestmentTransactionModel {
    return new InvestmentTransactionModel(
      record.bookId,
      record.assetId,
      record.transactionType,
      record.price,
      record.quantity,
      record.amount,
      record.fee,
      record.relatedAccountId,
      record.remarks,
      record.createTime,
      record.id
    );
  }
}
