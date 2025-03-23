/**
 * 投资账本数据库帮助类
 */
import dataRdb from '@ohos.data.relationalStore';
import { DBConnectionHolder } from './DBConnectionHolder';
import { InvestmentBookModel, InvestmentType } from '../model/InvestmentBookModel';
import { BookingConstants } from '../constants/BookingConstants';
import { DatabaseError } from '../errors/DatabaseError';
import { AccountBookModel } from '../model/AccountBookModel';
import { BookDBHelper } from './BookDBHelper';
import { IconUtils } from '../utils/IconUtils'; // 引入IconUtils

/**
 * 投资账本数据库帮助类
 * 注意：投资账本使用的是现有的账本表(account_book)，通过type字段区分普通账本和投资账本
 */
export class InvestmentBookDBHelper {
  private connection: DBConnectionHolder | null = null;
  private static instance: InvestmentBookDBHelper = new InvestmentBookDBHelper();
  private bookDBHelper: BookDBHelper | null = null;

  // 使用现有账本表
  public static readonly TABLE_INVESTMENT_BOOK: string = BookingConstants.TABLE_ACCOUNT_BOOK;
  
  constructor() {
    this.init();
  }
  
  /**
   * 获取实例
   * @returns InvestmentBookDBHelper实例
   */
  public static getInstance(): InvestmentBookDBHelper {
    return InvestmentBookDBHelper.instance;
  }
  
  /**
   * 初始化
   */
  private async init(): Promise<void> {
    this.connection = DBConnectionHolder.getInstance();
    this.bookDBHelper = BookDBHelper.getInstance();
    await this.connection.initDB();
  }

  /**
   * 创建投资账本
   * @param book 投资账本模型
   * @returns 创建结果ID
   */
  public async createInvestmentBook(book: InvestmentBookModel): Promise<number> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '创建账本', 1001);
      }
      
      // 创建一个AccountBookModel对象
      const accountBook = new AccountBookModel(
        book.name,
        BookingConstants.ACCOUNT_TYPE_STOCK, // 设置类型为股票账本
        book.balance,
        book.icon,
        0 // 非默认账本
      );
      
      // 使用已有的BookDBHelper插入账本数据
      const bookId = await this.bookDBHelper?.insertAccountBook(accountBook);
      
      return bookId ?? -1;
    } catch (error) {
      console.error('创建投资账本失败', error);
      throw new DatabaseError('创建投资账本失败', '创建账本', 1002);
    }
  }
  
  /**
   * 获取所有投资账本
   * @returns 投资账本列表
   */
  public async getAllInvestmentBooks(): Promise<InvestmentBookModel[]> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '获取账本列表', 1001);
      }
      
      // 构造RdbPredicates对象
      const predicates = new dataRdb.RdbPredicates(InvestmentBookDBHelper.TABLE_INVESTMENT_BOOK);
      predicates.equalTo('type', BookingConstants.ACCOUNT_TYPE_STOCK);
      
      const resultSet = await this.connection.query(predicates, undefined);
      const books: InvestmentBookModel[] = [];
      
      if (!resultSet) {
        return [];
      }
      
      while (resultSet.goToNextRow()) {
        const book = this.buildBookFromResultSet(resultSet);
        books.push(book);
      }
      
      resultSet.close();
      return books;
    } catch (error) {
      console.error('获取投资账本列表失败', error);
      throw new DatabaseError('获取投资账本列表失败', '获取账本列表', 1002);
    }
  }
  
  /**
   * 获取投资账本
   * @param id 投资账本ID
   * @returns 投资账本
   */
  public async getInvestmentBookById(id: number): Promise<InvestmentBookModel | null> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '获取账本', 1101);
      }
      
      // 构造RdbPredicates对象
      const predicates = new dataRdb.RdbPredicates(InvestmentBookDBHelper.TABLE_INVESTMENT_BOOK);
      predicates.equalTo('id', id).and().equalTo('type', BookingConstants.ACCOUNT_TYPE_STOCK);
      
      const resultSet = await this.connection.query(predicates, undefined);
      
      if (!resultSet) {
        return null;
      }
      
      if (resultSet.goToFirstRow()) {
        const book = this.buildBookFromResultSet(resultSet);
        resultSet.close();
        return book;
      }
      
      resultSet.close();
      return null;
    } catch (error) {
      console.error('获取投资账本详情失败', error);
      throw new DatabaseError('获取投资账本详情失败', '获取账本', 1102);
    }
  }
  
  /**
   * 更新投资账本
   * @param book 投资账本
   * @returns 是否更新成功
   */
  public async updateInvestmentBook(book: InvestmentBookModel): Promise<boolean> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '更新账本', 1201);
      }
      
      if (book.id === undefined) {
        throw new DatabaseError('账本ID不能为空', '更新账本', 1202);
      }
      
      // 修改数据
      const valuesBucket: dataRdb.ValuesBucket = {
        name: book.name,
        balance: book.balance,
        icon: typeof book.icon === 'string' ? book.icon : '', // 确保icon是字符串类型
        updateTime: Date.now()
      };
      
      // 条件语句
      const predicates = new dataRdb.RdbPredicates(InvestmentBookDBHelper.TABLE_INVESTMENT_BOOK);
      predicates.equalTo('id', book.id);
      
      // 更新数据
      const result = await this.connection.update(valuesBucket, predicates);
      
      console.info('更新投资账本成功');
      return result !== undefined && result > 0;
    } catch (error) {
      console.error('更新投资账本失败', error);
      throw new DatabaseError('更新投资账本失败', '更新账本', 1203);
    }
  }
  
  /**
   * 删除投资账本
   * @param id 投资账本ID
   * @returns 是否删除成功
   */
  public async deleteInvestmentBook(id: number): Promise<boolean> {
    try {
      // 直接使用BookDBHelper的删除方法
      return await this.bookDBHelper?.deleteAccountBook(id) ?? false;
    } catch (error) {
      console.error('删除投资账本失败', error);
      return false;
    }
  }

  /**
   * 从结果集构建投资账本模型
   * @param resultSet 结果集
   * @returns 投资账本模型
   */
  private buildBookFromResultSet(resultSet: dataRdb.ResultSet): InvestmentBookModel {
    const id: number = resultSet.getLong(resultSet.getColumnIndex('id'));
    const name: string = resultSet.getString(resultSet.getColumnIndex('name'));
    const balance: number = resultSet.getDouble(resultSet.getColumnIndex('balance'));
    const iconStr: string = resultSet.getString(resultSet.getColumnIndex('icon'));
    const createTime: number = resultSet.getLong(resultSet.getColumnIndex('createTime'));
    
    // 使用IconUtils将字符串转换为Resource类型
    const book = new InvestmentBookModel(
      name,
      InvestmentType.STOCK, // 默认使用股票类型，实际应该由前端选择
      balance,
      IconUtils.getResourceByKey(iconStr || BookingConstants.ICON_MISC),
      id
    );
    
    return book;
  }

}
