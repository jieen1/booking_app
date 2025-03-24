/**
 * 投资交易记录数据库帮助类
 */
import dataRdb from '@ohos.data.relationalStore';
import { InvestmentTransactionModel, TransactionType } from '../model/InvestmentTransactionModel';
import { DBConnectionHolder } from './DBConnectionHolder';
import { ValueType } from '@kit.ArkData';

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
  
  /**
   * 获取投资账本的所有交易记录
   * @param bookId 投资账本ID
   * @param startTime 开始时间（可选）
   * @param endTime 结束时间（可选）
   * @returns 交易记录列表
   */
  public async getTransactionsByBookId(
    bookId: number, 
    startTime?: number, 
    endTime?: number
  ): Promise<InvestmentTransactionModel[]> {
    try {
      let sql = `
        SELECT * FROM ${InvestmentTransactionDBHelper.TABLE_INVESTMENT_TRANSACTION}
        WHERE bookId = ?
      `;
      
      // 修改params数组定义，确保参数类型符合DBConnectionHolder中定义的querySql方法需要的Array<string | number>类型
      const params: Array<string | number> = [bookId];
      
      // 添加时间范围条件
      if (startTime !== undefined) {
        sql += ' AND transactionTime >= ?';
        params.push(startTime);
      }
      
      if (endTime !== undefined) {
        sql += ' AND transactionTime <= ?';
        params.push(endTime);
      }
      
      sql += ' ORDER BY transactionTime DESC';
      
      if (!this.connection) {
        return [];
      }
      
      const resultSet = await this.connection.querySql(sql, params);
      if (!resultSet) {
        return [];
      }
      
      const transactions: InvestmentTransactionModel[] = [];
      
      while (resultSet.goToNextRow()) {
        const transaction = this.createTransactionFromResultSet(resultSet);
        if (transaction) {
          transactions.push(transaction);
        }
      }
      
      resultSet.close();
      return transactions;
    } catch (error) {
      console.error(`查询投资账本(ID:${bookId})的交易记录失败`, error);
      return [];
    }
  }
  
  /**
   * 获取指定资产的所有交易记录
   * @param assetId 资产ID
   * @returns 交易记录列表
   */
  public async getTransactionsByAssetId(assetId: number): Promise<InvestmentTransactionModel[]> {
    try {
      const sql = `
        SELECT * FROM ${InvestmentTransactionDBHelper.TABLE_INVESTMENT_TRANSACTION}
        WHERE assetId = ?
        ORDER BY transactionTime DESC
      `;
      
      if (!this.connection) {
        return [];
      }
      
      // 修改params数组定义，确保参数类型符合DBConnectionHolder中定义的querySql方法需要的Array<string | number>类型
      const params: Array<string | number> = [assetId];
      const resultSet = await this.connection.querySql(sql, params);
      if (!resultSet) {
        return [];
      }
      
      const transactions: InvestmentTransactionModel[] = [];
      
      while (resultSet.goToNextRow()) {
        const transaction = this.createTransactionFromResultSet(resultSet);
        if (transaction) {
          transactions.push(transaction);
        }
      }
      
      resultSet.close();
      return transactions;
    } catch (error) {
      console.error(`查询资产(ID:${assetId})的交易记录失败`, error);
      return [];
    }
  }
  
  /**
   * 根据ID获取交易记录
   * @param id 交易记录ID
   * @returns 交易记录模型
   */
  public async getTransactionById(id: number): Promise<InvestmentTransactionModel | null> {
    try {
      const sql = `
        SELECT * FROM ${InvestmentTransactionDBHelper.TABLE_INVESTMENT_TRANSACTION}
        WHERE id = ?
      `;
      
      if (!this.connection) {
        return null;
      }
      
      // 修改params数组定义，确保参数类型符合DBConnectionHolder中定义的querySql方法需要的Array<string | number>类型
      const params: Array<string | number> = [id];
      const resultSet = await this.connection.querySql(sql, params);
      if (!resultSet) {
        return null;
      }
      
      if (resultSet.goToFirstRow()) {
        const transaction = this.createTransactionFromResultSet(resultSet);
        resultSet.close();
        return transaction;
      }
      
      resultSet.close();
      return null;
    } catch (error) {
      console.error(`获取交易记录(ID:${id})失败`, error);
      return null;
    }
  }
  
  /**
   * 删除交易记录
   * @param id 交易记录ID
   * @returns 是否删除成功
   */
  public async deleteTransaction(id: number): Promise<boolean> {
    try {
      if (!this.connection) {
        return false;
      }
      
      const sql = `DELETE FROM ${InvestmentTransactionDBHelper.TABLE_INVESTMENT_TRANSACTION} WHERE id = ?`;
      
      await this.connection.executeSql(sql, [id]);
      return true;
    } catch (error) {
      console.error(`删除交易记录(ID:${id})失败`, error);
      return false;
    }
  }
  
  /**
   * 删除账本下的所有交易记录
   * @param bookId 账本ID
   * @returns 是否删除成功
   */
  public async deleteTransactionsByBookId(bookId: number): Promise<boolean> {
    try {
      if (!this.connection) {
        return false;
      }
      
      const sql = `DELETE FROM ${InvestmentTransactionDBHelper.TABLE_INVESTMENT_TRANSACTION} WHERE bookId = ?`;
      
      await this.connection.executeSql(sql, [bookId]);
      return true;
    } catch (error) {
      console.error(`删除账本(ID:${bookId})的交易记录失败`, error);
      return false;
    }
  }
  
  /**
   * 删除资产相关的所有交易记录
   * @param assetId 资产ID
   * @returns 是否删除成功
   */
  public async deleteTransactionsByAssetId(assetId: number): Promise<boolean> {
    try {
      if (!this.connection) {
        return false;
      }
      
      const sql = `DELETE FROM ${InvestmentTransactionDBHelper.TABLE_INVESTMENT_TRANSACTION} WHERE assetId = ?`;
      
      await this.connection.executeSql(sql, [assetId]);
      return true;
    } catch (error) {
      console.error(`删除资产(ID:${assetId})的交易记录失败`, error);
      return false;
    }
  }

  /**
   * 从数据库结果集创建交易记录对象
   * @param resultSet 数据库结果集
   * @returns 交易记录对象
   */
  private createTransactionFromResultSet(resultSet: dataRdb.ResultSet): InvestmentTransactionModel | null {
    if (!resultSet) {
      return null;
    }
    
    try {
      const id = resultSet.getLong(resultSet.getColumnIndex('id'));
      const bookId = resultSet.getLong(resultSet.getColumnIndex('bookId'));
      const assetId = resultSet.getLong(resultSet.getColumnIndex('assetId'));
      const transactionType = resultSet.getLong(resultSet.getColumnIndex('transactionType'));
      const price = resultSet.getDouble(resultSet.getColumnIndex('price'));
      const quantity = resultSet.getDouble(resultSet.getColumnIndex('quantity'));
      const amount = resultSet.getDouble(resultSet.getColumnIndex('amount'));
      const fee = resultSet.getDouble(resultSet.getColumnIndex('fee'));
      const relatedAccountId = resultSet.getLong(resultSet.getColumnIndex('relatedAccountId'));
      const remarks = resultSet.getString(resultSet.getColumnIndex('remarks'));
      
      return new InvestmentTransactionModel(
        bookId,
        assetId,
        transactionType as TransactionType,
        price,
        quantity,
        amount,
        fee,
        relatedAccountId,
        remarks,
        id
      );
    } catch (error) {
      console.error('创建交易记录对象失败', error);
      return null;
    }
  }
}
