import dataRdb from '@ohos.data.relationalStore';
import { BookingConstants } from '../constants/BookingConstants';
import { CategoryModel } from '../model/CategoryModel';
import { RecordModel } from '../model/RecordModel';
import { RecordWithCategory } from '../model/RecordWithCategory';
import { AccountBookModel } from '../model/AccountBookModel';
import { DBConnectionHolder } from './DBConnectionHolder';
import { IconUtils } from '../utils/IconUtils';
import { CategorySummary, SummaryData } from '../model/SummaryModel';


/**
 * 数据库帮助类
 */
export class BookDBHelper {
  private connection: DBConnectionHolder | null = null;
  private static instance: BookDBHelper = new BookDBHelper();

  constructor() {
    this.initDB()
  }

  /**
   * 获取实例
   * @returns DBHelper实例
   */
  public static getInstance(): BookDBHelper {
    return BookDBHelper.instance;
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
    
    console.info('初始化数据库');
    
    try {
      this.connection = DBConnectionHolder.getInstance();
      await this.connection.initDB();
      
      // 确保账本表存在
      await this.connection.executeSql(
        'CREATE TABLE IF NOT EXISTS ' + BookingConstants.TABLE_ACCOUNT_BOOK + ' ' +
        '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'name TEXT, ' +
        'type INTEGER, ' +
        'balance REAL, ' +
        'isDefault INTEGER DEFAULT 0, ' +
        'icon TEXT, ' +
        'createTime INTEGER)'
      );

      // 初始化默认账本
      await this.initDefaultAccountBook();
      
      return true;
    } catch (err) {
      console.error('Init database failed: ' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * 初始化默认账本
   */
  private async initDefaultAccountBook(): Promise<void> {
    // 检查账本表是否为空
    const count = await this.getAccountBooksCount();
    if (count > 0) {
      console.info('账本表已有数据，跳过初始化默认账本');
      return;
    }
    
    console.info('账本表为空，开始初始化默认账本');
    
    try {
      // 插入默认账本
      const defaultAccountBook = new AccountBookModel(
        '默认账本',
        BookingConstants.ACCOUNT_BOOK_TYPE_DEFAULT,
        0,
        IconUtils.getResourceByKey(BookingConstants.ICON_ACCOUNT_BOOK_DEFAULT),
        1,
        1
      );
      
      await this.insertAccountBook(defaultAccountBook);
      
      console.info('初始化默认账本数据完成');
    } catch (err) {
      console.error('初始化默认账本失败：', JSON.stringify(err));
    }
  }

  /**
   * 获取账本数量
   */
  private async getAccountBooksCount(): Promise<number> {

    try {
      const sql = 'SELECT COUNT(*) AS count FROM ' + BookingConstants.TABLE_ACCOUNT_BOOK;
      const resultSet = await this.connection?.querySql(sql);
      
      let count = 0;
      if (resultSet && resultSet.goToFirstRow()) {
        count = resultSet.getDouble(resultSet.getColumnIndex('count'));
      }
      
      resultSet?.close();
      return count;
    } catch (err) {
      console.error('Get account books count failed: ' + JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 插入账本
   * @param accountBook 账本数据
   */
  public async insertAccountBook(accountBook: AccountBookModel): Promise<number> {

    try {
      const valuesBucket: dataRdb.ValuesBucket = {
        name: accountBook.name,
        type: accountBook.type,
        balance: accountBook.balance,
        isDefault: accountBook.isDefault,
        icon: IconUtils.getIconKeyByTypeAndName(BookingConstants.BOOK_TYPE, accountBook.type),
        createTime: new Date().getTime()
      };
      
      const rowId = await this.connection?.insert(BookingConstants.TABLE_ACCOUNT_BOOK, valuesBucket);
      return rowId ?? -1;
    } catch (err) {
      console.error('Insert account book failed: ' + JSON.stringify(err));
      return -1;
    }
  }

  /**
   * 获取所有账本
   */
  public async getAllAccountBooks(): Promise<AccountBookModel[]> {

    try {
      // 查询所有账本，默认账本始终排在第一位
      const sql = 'SELECT * FROM ' + BookingConstants.TABLE_ACCOUNT_BOOK + ' ORDER BY isDefault DESC, id ASC';
      const resultSet = await this.connection?.querySql(sql);
      
      const accountBooks: AccountBookModel[] = [];
      
      if (resultSet) {
        while (resultSet.goToNextRow()) {
          const id = resultSet.getLong(resultSet.getColumnIndex('id'));
          const name = resultSet.getString(resultSet.getColumnIndex('name'));
          const type = resultSet.getLong(resultSet.getColumnIndex('type'));
          const balance = resultSet.getDouble(resultSet.getColumnIndex('balance'));
          const isDefault = resultSet.getLong(resultSet.getColumnIndex('isDefault'));
          const iconStr = resultSet.getString(resultSet.getColumnIndex('icon'));
          const createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));

          const accountBook = new AccountBookModel(name, type, balance, IconUtils.getResourceByKey(iconStr), isDefault, id);
          accountBook.createTime = createTime;
          
          accountBooks.push(accountBook);
        }
        
        resultSet.close();
      }
      
      return accountBooks;
    } catch (err) {
      console.error('获取所有账本失败: ' + JSON.stringify(err));
      return [];
    }
  }
  
  /**
   * 获取默认账本
   */
  public async getDefaultAccountBook(): Promise<AccountBookModel | null> {

    try {
      const sql = 'SELECT * FROM ' + BookingConstants.TABLE_ACCOUNT_BOOK + ' WHERE isDefault = 1 LIMIT 1';
      const resultSet = await this.connection?.querySql(sql);
      
      let accountBook: AccountBookModel | null = null;
      
      if (resultSet && resultSet.goToFirstRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        const type = resultSet.getLong(resultSet.getColumnIndex('type'));
        const balance = resultSet.getDouble(resultSet.getColumnIndex('balance'));
        const isDefault = resultSet.getLong(resultSet.getColumnIndex('isDefault'));
        const iconStr = resultSet.getString(resultSet.getColumnIndex('icon'));
        const createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));
        
        accountBook = new AccountBookModel(name, type, balance, IconUtils.getResourceByKey(iconStr), isDefault, id);
        accountBook.createTime = createTime;
        
        resultSet.close();
      }
      
      // 如果没有找到默认账本，则创建一个
      if (!accountBook) {
        await this.initDefaultAccountBook();
        return this.getDefaultAccountBook();
      }
      
      return accountBook;
    } catch (err) {
      console.error('获取默认账本失败: ' + JSON.stringify(err));
      return null;
    }
  }
  
  /**
   * 获取账本详情
   * @param accountId 账本ID
   */
  public async getAccountBookById(accountId: number): Promise<AccountBookModel | null> {

    if (!accountId) {
      return this.getDefaultAccountBook();
    }
    
    try {
      const sql = 'SELECT * FROM ' + BookingConstants.TABLE_ACCOUNT_BOOK + ' WHERE id = ? LIMIT 1';
      const resultSet = await this.connection?.querySql(sql, [accountId]);
      
      let accountBook: AccountBookModel | null = null;
      
      if (resultSet && resultSet.goToFirstRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        const type = resultSet.getLong(resultSet.getColumnIndex('type'));
        const balance = resultSet.getDouble(resultSet.getColumnIndex('balance'));
        const isDefault = resultSet.getLong(resultSet.getColumnIndex('isDefault'));
        const iconStr = resultSet.getString(resultSet.getColumnIndex('icon'));
        const createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));

        accountBook = new AccountBookModel(name, type, balance, IconUtils.getResourceByKey(iconStr), isDefault, id);
        accountBook.createTime = createTime;
        
        resultSet.close();
      }
      
      return accountBook;
    } catch (err) {
      console.error('获取账本详情失败: ' + JSON.stringify(err));
      return null;
    }
  }
  
  /**
   * 更新账本余额
   * @param accountId 账本ID
   * @param amount 变动金额（正数增加，负数减少）
   */
  public async updateAccountBalance(accountId: number, amount: number): Promise<boolean> {

    try {
      // 先获取当前余额
      const accountBook = await this.getAccountBookById(accountId);
      if (!accountBook || accountBook.id === undefined) {
        return false;
      }
      
      // 计算新余额
      const newBalance = accountBook.balance + amount;
      
      // 更新余额
      const valuesBucket: dataRdb.ValuesBucket = {
        balance: newBalance
      };
      
      const predicates = new dataRdb.RdbPredicates(BookingConstants.TABLE_ACCOUNT_BOOK);
      predicates.equalTo('id', accountBook.id);
      
      const count = await this.connection?.update(valuesBucket, predicates);
      return count !== undefined && count > 0;
    } catch (err) {
      console.error('更新账本余额失败: ' + JSON.stringify(err));
      return false;
    }
  }
  
  /**
   * 设置默认账本
   * @param accountId 账本ID
   */
  public async setDefaultAccountBook(accountId: number): Promise<boolean> {

    try {
      // 先将所有账本设置为非默认
      let valuesBucket: dataRdb.ValuesBucket = {
        isDefault: BookingConstants.ACCOUNT_NOT_DEFAULT
      };
      
      let predicates = new dataRdb.RdbPredicates(BookingConstants.TABLE_ACCOUNT_BOOK);
      await this.connection?.update(valuesBucket, predicates);
      
      // 设置指定账本为默认
      valuesBucket = {
        isDefault: BookingConstants.ACCOUNT_IS_DEFAULT
      };
      
      predicates = new dataRdb.RdbPredicates(BookingConstants.TABLE_ACCOUNT_BOOK);
      predicates.equalTo('id', accountId);
      
      const count = await this.connection?.update(valuesBucket, predicates);
      return count !== undefined && count > 0;
    } catch (err) {
      console.error('设置默认账本失败: ' + JSON.stringify(err));
      return false;
    }
  }
  
  /**
   * 删除账本（非默认账本）
   * @param accountId 账本ID
   */
  public async deleteAccountBook(accountId: number): Promise<boolean> {

    try {
      // 检查是否为默认账本，不允许删除默认账本
      const accountBook = await this.getAccountBookById(accountId);
      if (!accountBook || accountBook.isDefault === BookingConstants.ACCOUNT_IS_DEFAULT) {
        console.error('不能删除默认账本');
        return false;
      }
      
      const predicates = new dataRdb.RdbPredicates(BookingConstants.TABLE_ACCOUNT_BOOK);
      predicates.equalTo('id', accountId);
      
      const count = await this.connection?.delete(predicates);
      return count !== undefined && count > 0;
    } catch (err) {
      console.error('删除账本失败: ' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * 获取账本记录列表
   * @param accountBookId 账本ID
   * @param type 记录类型（可选）
   * @param startDate 开始日期（可选）
   * @param endDate 结束日期（可选）
   */
  public async getRecordsByAccountBook(
    accountBookId: number,
    type?: number,
    startDate?: number,
    endDate?: number
  ): Promise<RecordWithCategory[]> {

    try {
      let sql = `SELECT r.*, c.name as categoryName, c.icon as categoryIcon, c.type as categoryType 
                FROM ${BookingConstants.TABLE_RECORD} r 
                LEFT JOIN ${BookingConstants.TABLE_CATEGORY} c 
                ON r.categoryId = c.id`;
      
      const params: (string | number)[] = [];
      const conditions: string[] = [];
      
      // 添加账本ID条件
      conditions.push('r.accountBookId = ?');
      params.push(accountBookId);
      
      if (type !== undefined) {
        conditions.push('r.type = ?');
        params.push(type);
      }
      
      if (startDate) {
        conditions.push('r.recordTime >= ?');
        params.push(startDate);
      }
      
      if (endDate) {
        conditions.push('r.recordTime <= ?');
        params.push(endDate);
      }
      
      if (conditions.length > 0) {
        sql += ' WHERE ' + conditions.join(' AND ');
      }
      
      // 排序
      sql += ' ORDER BY r.recordTime DESC';
      
      const resultSet = await this.connection?.querySql(sql, params);
      const records: RecordWithCategory[] = [];
      
      if (resultSet) {
        while (resultSet.goToNextRow()) {
          const id = resultSet.getLong(resultSet.getColumnIndex('id'));
          const type = resultSet.getLong(resultSet.getColumnIndex('type'));
          const categoryId = resultSet.getLong(resultSet.getColumnIndex('categoryId'));
          const amount = resultSet.getDouble(resultSet.getColumnIndex('amount'));
          const description = resultSet.getString(resultSet.getColumnIndex('description'));
          const recordTime = resultSet.getLong(resultSet.getColumnIndex('recordTime'));
          const accountBookId = resultSet.getLong(resultSet.getColumnIndex('accountBookId'));
          const createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));
          
          // 类别信息
          const categoryName = resultSet.getString(resultSet.getColumnIndex('categoryName'));
          const categoryIcon = resultSet.getString(resultSet.getColumnIndex('categoryIcon'));
          
          // 创建记录对象
          const record = new RecordModel(
            type, categoryId, amount, description, recordTime, accountBookId
          );
          record.id = id;
          record.createTime = createTime;
          
          // 创建类别对象
          const category = new CategoryModel(
            type, // 类别类型
            categoryName,
            IconUtils.getResourceByKey(categoryIcon),
            categoryId
          );
          
          // 创建带类别的记录对象
          const recordWithCategory = new RecordWithCategory(record, category);
          
          records.push(recordWithCategory);
        }
        
        resultSet.close();
      }
      
      return records;
    } catch (err) {
      console.error('获取账本记录列表失败: ' + JSON.stringify(err));
      return [];
    }
  }

  /**
   * 获取账本统计数据
   * @param accountBookId 账本ID
   * @param startDate 开始日期（可选）
   * @param endDate 结束日期（可选）
   */
  public async getAccountBookSummary(
    accountBookId: number,
    startDate?: number,
    endDate?: number
  ): Promise<SummaryData> {

    const summary: SummaryData = {
      income: 0,
      expense: 0
    };
    
    try {
      let sql = `SELECT type, SUM(amount) as total 
                FROM ${BookingConstants.TABLE_RECORD} 
                WHERE accountBookId = ?`;
      
      const params: (string | number)[] = [accountBookId];
      
      if (startDate) {
        sql += ' AND recordTime >= ?';
        params.push(startDate);
      }
      
      if (endDate) {
        sql += ' AND recordTime <= ?';
        params.push(endDate);
      }
      
      sql += ' GROUP BY type';
      
      const resultSet = await this.connection?.querySql(sql, params);
      
      if (resultSet) {
        while (resultSet.goToNextRow()) {
          const type = resultSet.getLong(resultSet.getColumnIndex('type'));
          const total = resultSet.getDouble(resultSet.getColumnIndex('total'));
          
          if (type === BookingConstants.RECORD_TYPE_INCOME) {
            summary.income = total;
          } else if (type === BookingConstants.RECORD_TYPE_EXPENSE) {
            summary.expense = total;
          }
        }
        resultSet.close();
      }
      
      return summary;
    } catch (err) {
      console.error('获取账本统计数据失败: ' + JSON.stringify(err));
      return summary;
    }
  }

  /**
   * 获取账本分类统计数据
   * @param accountBookId 账本ID
   * @param type 记录类型（可选）
   * @param startDate 开始日期（可选）
   * @param endDate 结束日期（可选）
   */
  public async getCategorySummaryByAccountBook(
    accountBookId: number,
    type: number,
    startDate?: number,
    endDate?: number
  ): Promise<CategorySummary[]> {

    try {
      let sql = `SELECT r.categoryId, c.name as categoryName, c.icon as categoryIcon, SUM(r.amount) as total 
                FROM ${BookingConstants.TABLE_RECORD} r 
                LEFT JOIN ${BookingConstants.TABLE_CATEGORY} c 
                ON r.categoryId = c.id 
                WHERE r.type = ? AND r.accountBookId = ?`;
      
      const params: (string | number)[] = [type, accountBookId];
      
      if (startDate) {
        sql += ' AND r.recordTime >= ?';
        params.push(startDate);
      }
      
      if (endDate) {
        sql += ' AND r.recordTime <= ?';
        params.push(endDate);
      }
      
      sql += ' GROUP BY r.categoryId ORDER BY total DESC';
      
      const resultSet = await this.connection?.querySql(sql, params);
      
      const categorySummaries: CategorySummary[] = [];
      
      if (resultSet) {
        while (resultSet.goToNextRow()) {
          const categoryId = resultSet.getLong(resultSet.getColumnIndex('categoryId'));
          const categoryName = resultSet.getString(resultSet.getColumnIndex('categoryName'));
          const categoryIcon = resultSet.getString(resultSet.getColumnIndex('categoryIcon'));
          const total = resultSet.getDouble(resultSet.getColumnIndex('total'));
          
          categorySummaries.push({
            categoryId: categoryId,
            categoryName: categoryName,
            icon: categoryIcon,
            amount: total
          });
        }
        resultSet.close();
      }
      
      return categorySummaries;
    } catch (err) {
      console.error('获取账本分类统计数据失败: ' + JSON.stringify(err));
      return [];
    }
  }
}
