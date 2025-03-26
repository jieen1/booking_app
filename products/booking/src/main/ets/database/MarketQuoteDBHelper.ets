/**
 * 市场行情数据库帮助类
 * 用于管理市场行情数据的缓存和查询
 */
import { MarketQuoteModel } from '../model/MarketQuoteModel';
import { DBConnectionHolder } from './DBConnectionHolder';
import { ValueType } from '@kit.ArkData';

/**
 * 市场行情数据库帮助类
 */
export class MarketQuoteDBHelper {
  private connection: DBConnectionHolder | null = null;
  private static instance: MarketQuoteDBHelper = new MarketQuoteDBHelper();

  // 市场行情表名
  private static readonly TABLE_MARKET_QUOTE: string = 'market_quote';
  
  constructor() {
    this.initDB();
  }

  /**
   * 获取实例
   * @returns MarketQuoteDBHelper实例
   */
  public static getInstance(): MarketQuoteDBHelper {
    return MarketQuoteDBHelper.instance;
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
    
    console.info('初始化市场行情数据库');
    
    try {
      this.connection = DBConnectionHolder.getInstance();
      await this.connection.initDB();
      
      // 创建市场行情表
      await this.createMarketQuoteTable();
      
      return true;
    } catch (error) {
      console.error('初始化市场行情数据库失败', error);
      return false;
    }
  }
  
  /**
   * 创建市场行情表
   */
  private async createMarketQuoteTable(): Promise<void> {
    if (!this.connection) {
      throw new Error('数据库连接未初始化');
    }
    
    const sql = `
      CREATE TABLE IF NOT EXISTS ${MarketQuoteDBHelper.TABLE_MARKET_QUOTE} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        currentPrice REAL NOT NULL,
        changeAmount REAL NOT NULL,
        changePercent REAL NOT NULL,
        openPrice REAL NOT NULL,
        highPrice REAL NOT NULL,
        lowPrice REAL NOT NULL,
        closePrice REAL NOT NULL,
        volume REAL NOT NULL,
        turnover REAL NOT NULL,
        updateTime INTEGER NOT NULL,
        source TEXT NOT NULL
      )
    `;
    
    try {
      await this.connection.executeSql(sql);
      console.info('创建市场行情表成功');
      
      // 创建代码索引以提高查询性能
      await this.createCodeIndex();
    } catch (error) {
      console.error('创建市场行情表失败', error);
    }
  }
  
  /**
   * 创建代码索引
   */
  private async createCodeIndex(): Promise<void> {
    if (!this.connection) {
      throw new Error('数据库连接未初始化');
    }
    
    try {
      const sql = `CREATE INDEX IF NOT EXISTS idx_market_quote_code ON ${MarketQuoteDBHelper.TABLE_MARKET_QUOTE} (code)`;
      await this.connection.executeSql(sql);
      console.info('创建市场行情代码索引成功');
    } catch (error) {
      console.error('创建市场行情代码索引失败', error);
    }
  }
  
  /**
   * 保存或更新市场行情数据
   * @param quote 市场行情数据
   * @returns 操作是否成功
   */
  public async saveOrUpdateQuote(quote: MarketQuoteModel): Promise<boolean> {
    if (!this.connection) {
      return false;
    }
    
    try {
      // 先检查是否已存在该代码的记录
      const existingQuote = await this.getQuoteByCode(quote.code);
      
      if (existingQuote) {
        // 更新现有记录
        return await this.updateQuote(quote);
      } else {
        // 插入新记录
        await this.insertQuote(quote);
        return true;
      }
    } catch (error) {
      console.error(`保存或更新市场行情数据失败，代码: ${quote.code}`, error);
      return false;
    }
  }
  
  /**
   * 插入市场行情数据
   * @param quote 市场行情数据
   * @returns 新插入记录的ID
   */
  private async insertQuote(quote: MarketQuoteModel): Promise<number> {
    if (!this.connection) {
      throw new Error('数据库连接未初始化');
    }
    
    try {
      const sql = `
        INSERT INTO ${MarketQuoteDBHelper.TABLE_MARKET_QUOTE} (
          code, name, currentPrice, changeAmount, changePercent, 
          openPrice, highPrice, lowPrice, closePrice, 
          volume, turnover, updateTime, source
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;
      
      const now = new Date().getTime();
      const bindParams: ValueType[] = [
        quote.code,
        quote.name,
        quote.currentPrice,
        quote.changeAmount,
        quote.changePercent,
        quote.openPrice,
        quote.highPrice,
        quote.lowPrice,
        quote.closePrice,
        quote.volume,
        quote.turnover,
        quote.updateTime || now,
        quote.source || ''
      ];
      // FIXME
      await this.connection.executeSql(sql, bindParams);
      
      // 获取最后插入的ID
      let id = 0;
      try {
        // 执行查询最后插入的ID的SQL
        const queryLastInsertIdResult = await this.connection.querySql('SELECT last_insert_rowid() AS lastId', []);
        if (queryLastInsertIdResult) {
          // 检查是否有数据并获取第一行
          if (queryLastInsertIdResult.goToFirstRow()) {
            // 获取ID值
            id = queryLastInsertIdResult.getLong(queryLastInsertIdResult.getColumnIndex('lastId'));
          }
          // 关闭结果集
          queryLastInsertIdResult.close();
        }
      } catch (error) {
        console.error(`插入市场行情数据获取ID失败，代码: ${quote.code}`, error);
      }
      
      return id;
    } catch (error) {
      console.error(`插入市场行情数据失败，代码: ${quote.code}`, error);
      return 0; // 确保出错时也有返回值
    }
  }
  
  /**
   * 更新市场行情数据
   * @param quote 市场行情数据
   * @returns 是否更新成功
   */
  private async updateQuote(quote: MarketQuoteModel): Promise<boolean> {
    if (!this.connection) {
      return false;
    }
    
    try {
      const sql = `
        UPDATE ${MarketQuoteDBHelper.TABLE_MARKET_QUOTE} SET
          name = ?,
          currentPrice = ?,
          changeAmount = ?,
          changePercent = ?,
          openPrice = ?,
          highPrice = ?,
          lowPrice = ?,
          closePrice = ?,
          volume = ?,
          turnover = ?,
          updateTime = ?,
          source = ?
        WHERE code = ?
      `;
      
      const now = new Date().getTime();
      const bindParams = [
        quote.name,
        quote.currentPrice,
        quote.changeAmount,
        quote.changePercent,
        quote.openPrice,
        quote.highPrice,
        quote.lowPrice,
        quote.closePrice,
        quote.volume,
        quote.turnover,
        quote.updateTime || now,
        quote.source || '',
        quote.code
      ];
      
      await this.connection.executeSql(sql, bindParams);
      return true;
    } catch (error) {
      console.error(`更新市场行情数据失败，代码: ${quote.code}`, error);
      return false;
    }
  }
  
  /**
   * 根据代码获取市场行情数据
   * @param code 股票/基金代码
   * @returns 市场行情数据
   */
  public async getQuoteByCode(code: string): Promise<MarketQuoteModel | null> {
    // FIXME
    try {
      const sql = `
        SELECT * FROM ${MarketQuoteDBHelper.TABLE_MARKET_QUOTE}
        WHERE code = ?
      `;
      
      if (!this.connection) {
        return null;
      }
      
      const resultSet = await this.connection.querySql(sql, [code]);
      
      if (resultSet?.goToFirstRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        const currentPrice = resultSet.getDouble(resultSet.getColumnIndex('currentPrice'));
        const changeAmount = resultSet.getDouble(resultSet.getColumnIndex('changeAmount'));
        const changePercent = resultSet.getDouble(resultSet.getColumnIndex('changePercent'));
        const openPrice = resultSet.getDouble(resultSet.getColumnIndex('openPrice'));
        const highPrice = resultSet.getDouble(resultSet.getColumnIndex('highPrice'));
        const lowPrice = resultSet.getDouble(resultSet.getColumnIndex('lowPrice'));
        const closePrice = resultSet.getDouble(resultSet.getColumnIndex('closePrice'));
        const volume = resultSet.getDouble(resultSet.getColumnIndex('volume'));
        const turnover = resultSet.getDouble(resultSet.getColumnIndex('turnover'));
        const updateTime = resultSet.getLong(resultSet.getColumnIndex('updateTime'));
        const source = resultSet.getString(resultSet.getColumnIndex('source'));
        
        const quote = new MarketQuoteModel(
          code,
          name,
          currentPrice,
          changeAmount,
          changePercent,
          openPrice,
          highPrice,
          lowPrice,
          closePrice,
          volume,
          turnover,
          source,
          id
        );
        
        quote.updateTime = updateTime;
        
        resultSet.close();
        return quote;
      }
      
      resultSet?.close();
      return null;
    } catch (error) {
      console.error(`获取市场行情数据失败，代码: ${code}`, error);
      return null;
    }
  }
  
  /**
   * 获取所有市场行情数据
   * @returns 市场行情数据列表
   */
  public async getAllQuotes(): Promise<MarketQuoteModel[]> {
    try {
      const sql = `
        SELECT * FROM ${MarketQuoteDBHelper.TABLE_MARKET_QUOTE}
        ORDER BY code
      `;
      
      if (!this.connection) {
        return [];
      }
      
      const resultSet = await this.connection.querySql(sql);
      const quotes: MarketQuoteModel[] = [];
      
      while (resultSet?.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const code = resultSet.getString(resultSet.getColumnIndex('code'));
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        const currentPrice = resultSet.getDouble(resultSet.getColumnIndex('currentPrice'));
        const changeAmount = resultSet.getDouble(resultSet.getColumnIndex('changeAmount'));
        const changePercent = resultSet.getDouble(resultSet.getColumnIndex('changePercent'));
        const openPrice = resultSet.getDouble(resultSet.getColumnIndex('openPrice'));
        const highPrice = resultSet.getDouble(resultSet.getColumnIndex('highPrice'));
        const lowPrice = resultSet.getDouble(resultSet.getColumnIndex('lowPrice'));
        const closePrice = resultSet.getDouble(resultSet.getColumnIndex('closePrice'));
        const volume = resultSet.getDouble(resultSet.getColumnIndex('volume'));
        const turnover = resultSet.getDouble(resultSet.getColumnIndex('turnover'));
        const updateTime = resultSet.getLong(resultSet.getColumnIndex('updateTime'));
        const source = resultSet.getString(resultSet.getColumnIndex('source'));
        
        const quote = new MarketQuoteModel(
          code,
          name,
          currentPrice,
          changeAmount,
          changePercent,
          openPrice,
          highPrice,
          lowPrice,
          closePrice,
          volume,
          turnover,
          source,
          id
        );
        
        quote.updateTime = updateTime;
        quotes.push(quote);
      }
      
      resultSet?.close();
      return quotes;
    } catch (error) {
      console.error('获取所有市场行情数据失败', error);
      return [];
    }
  }
}
