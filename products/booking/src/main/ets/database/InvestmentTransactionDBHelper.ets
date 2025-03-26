/**
 * 投资交易记录数据库帮助类
 */
import dataRdb from '@ohos.data.relationalStore';
import { InvestmentTransactionModel } from '../model/InvestmentTransactionModel';
import { DBConnectionHolder } from './DBConnectionHolder';

/**
 * 投资交易记录数据库帮助类
 */
export class InvestmentTransactionDBHelper {
  private connection: DBConnectionHolder | null = null;
  private static instance: InvestmentTransactionDBHelper = new InvestmentTransactionDBHelper();

  // 投资交易记录表名
  private static readonly TABLE_INVESTMENT_TRANSACTION: string = 'investment_transaction';
  
  constructor() {
    this.initDB();
  }

  /**
   * 获取实例
   * @returns InvestmentTransactionDBHelper实例
   */
  public static getInstance(): InvestmentTransactionDBHelper {
    return InvestmentTransactionDBHelper.instance;
  }

  /**
   * 初始化数据库
   */
  public async initDB(): Promise<boolean> {
    return this.initDatabase();
  }

  /**
   * 初始化数据库
   * @returns 是否初始化成功
   */
  public async initDatabase(): Promise<boolean> {
    if (this.connection !== null) {
      return true;
    }
    
    console.info('初始化投资交易数据库');
    
    try {
      this.connection = DBConnectionHolder.getInstance();
      await this.connection.initDB();
      
      // 创建投资交易记录表
      await this.createTable();
      
      return true;
    } catch (error) {
      console.error('初始化投资交易数据库失败', error);
      return false;
    }
  }
  
  /**
   * 创建投资交易记录表
   */
  private async createTable(): Promise<void> {
    if (!this.connection) {
      throw new Error('数据库连接未初始化');
    }
    
    const sql = `
      CREATE TABLE IF NOT EXISTS ${InvestmentTransactionDBHelper.TABLE_INVESTMENT_TRANSACTION} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        assetId INTEGER NOT NULL,
        transactionType INTEGER NOT NULL,
        price REAL NOT NULL,
        quantity REAL NOT NULL,
        amount REAL NOT NULL,
        fee REAL NOT NULL,
        transactionTime INTEGER NOT NULL,
        relatedAccountId INTEGER,
        remarks TEXT,
        createTime INTEGER NOT NULL
      )
    `;
    
    try {
      await this.connection.executeSql(sql);
      console.info('创建投资交易记录表成功');
    } catch (error) {
      console.error('创建投资交易记录表失败', error);
      throw new Error(`创建投资交易记录表失败: ${error.message}`);
    }
  }
  
  /**
   * 创建投资交易记录
   * @param transaction 投资交易记录模型
   * @returns 创建的交易记录ID
   */
  public async createTransaction(transaction: InvestmentTransactionModel): Promise<number> {
    if (!this.connection) {
      throw new Error('数据库连接未初始化');
    }
    
    try {

      const valuesBucket: dataRdb.ValuesBucket = {
        bookId: transaction.bookId,
        assetId: transaction.assetId,
        transactionType: transaction.type,
        price: transaction.price,
        quantity: transaction.quantity,
        amount: transaction.amount,
        fee: transaction.fee,
        transactionTime: transaction.transactionTime,
        relatedAccountId: transaction.relatedAccountId,
        remarks: transaction.remarks,
        createTime: transaction.createTime || new Date().getTime()
      };
      
      const rowId = await this.connection.insert(InvestmentTransactionDBHelper.TABLE_INVESTMENT_TRANSACTION, valuesBucket);
      return rowId ?? -1;
    } catch (error) {
      console.error('创建投资交易记录失败', error);
      throw new Error(`创建投资交易记录失败: ${error.message}`);
    }
  }
}
