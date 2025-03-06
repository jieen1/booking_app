import dataRdb from '@ohos.data.relationalStore';
import { BookingConstants } from '../constants/BookingConstants';
import { CategoryModel } from '../model/CategoryModel';
import { RecordModel } from '../model/RecordModel';
import { RecordWithCategory } from '../model/RecordWithCategory';

/**
 * 重复分类组接口
 */
interface DuplicateCategoryGroup {
  keepId: number;
  type: number;
  name: string;
  count: number;
}

/**
 * 分类选项接口
 */
interface CategoryOption {
  type: number;
  name: string;
  icon: string;
}

/**
 * 数据库配置接口
 */
interface DBConfig {
  name: string;
  securityLevel: dataRdb.SecurityLevel;
}

/**
 * 统计数据接口
 */
interface SummaryData {
  income: number;
  expense: number;
}

/**
 * 分类统计接口
 */
interface CategorySummary {
  categoryId: number;
  categoryName: string;
  icon: string;
  amount: number;
}

/**
 * 数据库帮助类
 */
export class DBHelper {
  private rdbStore: dataRdb.RdbStore | null = null;
  private static instance: DBHelper = new DBHelper();

  /**
   * 获取实例
   * @returns DBHelper实例
   */
  public static getInstance(): DBHelper {
    return DBHelper.instance;
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
    if (this.rdbStore !== null) {
      return true;
    }
    
    console.info('初始化数据库');
    
    try {
      // 数据库配置
      const dbConfig: DBConfig = {
        name: BookingConstants.DB_NAME,
        securityLevel: dataRdb.SecurityLevel.S1
      };
      
      // 打开或创建数据库
      this.rdbStore = await dataRdb.getRdbStore(getContext(), dbConfig);
      
      // 确保记录表存在
      await this.rdbStore.executeSql(
        'CREATE TABLE IF NOT EXISTS ' + BookingConstants.TABLE_RECORD + ' ' +
        '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'type INTEGER, ' +
        'categoryId INTEGER, ' +
        'amount REAL, ' +
        'description TEXT, ' +
        'recordTime INTEGER, ' +
        'accountBookId INTEGER DEFAULT 1, ' +
        'createTime INTEGER)'
      );
      
      // 确保分类表存在
      await this.rdbStore.executeSql(
        'CREATE TABLE IF NOT EXISTS ' + BookingConstants.TABLE_CATEGORY + ' ' +
        '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'type INTEGER, ' +
        'name TEXT, ' +
        'icon TEXT, ' +
        'createTime INTEGER)'
      );
      
      // 确保账本表存在
      await this.rdbStore.executeSql(
        'CREATE TABLE IF NOT EXISTS ' + BookingConstants.TABLE_ACCOUNT_BOOK + ' ' +
        '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'name TEXT, ' +
        'type INTEGER, ' +
        'balance REAL, ' +
        'isDefault INTEGER DEFAULT 0, ' +
        'icon TEXT, ' +
        'createTime INTEGER)'
      );
      
      // 确保转账表存在
      await this.rdbStore.executeSql(
        'CREATE TABLE IF NOT EXISTS ' + BookingConstants.TABLE_TRANSFER + ' ' +
        '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'fromAccountId INTEGER, ' +
        'toAccountId INTEGER, ' +
        'amount REAL, ' +
        'description TEXT, ' +
        'relatedId INTEGER, ' +
        'transferTime INTEGER, ' +
        'createTime INTEGER)'
      );

      // 清理重复的分类数据
      try {
        await this.cleanDuplicateCategories();
      } catch (err) {
        console.error('清理重复分类时出错，继续初始化：' + JSON.stringify(err));
      }
      
      // 初始化默认分类数据（只在分类表为空时执行）
      await this.initDefaultCategories();
      
      // 初始化默认账本
      await this.initDefaultAccountBook();
      
      return true;
    } catch (err) {
      console.error('Init database failed: ' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * 清理重复的分类数据
   * 保留每个类型和名称组合中id最小的那一个，删除其他重复项
   */
  private async cleanDuplicateCategories(): Promise<void> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      console.info('开始清理重复的分类数据');
      
      // 查询所有分类，按照type和name分组，找出重复的项
      const sql = 'SELECT MIN(id) as keep_id, type, name, COUNT(*) as count ' +
                  'FROM ' + BookingConstants.TABLE_CATEGORY + ' ' +
                  'GROUP BY type, name ' +
                  'HAVING COUNT(*) > 1';
      
      const resultSet = await this.rdbStore?.querySql(sql);
      const duplicateGroups: DuplicateCategoryGroup[] = [];
      
      if (resultSet) {
        while (resultSet.goToNextRow()) {
          const keepId = resultSet.getLong(resultSet.getColumnIndex('keep_id'));
          const type = resultSet.getLong(resultSet.getColumnIndex('type'));
          const name = resultSet.getString(resultSet.getColumnIndex('name'));
          const count = resultSet.getLong(resultSet.getColumnIndex('count'));
          
          duplicateGroups.push({ keepId, type, name, count });
        }
        
        resultSet.close();
      }
      
      // 如果有重复的分类，对每组重复项执行删除操作
      if (duplicateGroups.length > 0) {
        for (const group of duplicateGroups) {
          console.info(`发现重复分类: 类型=${group.type}, 名称=${group.name}, 数量=${group.count}`);
          
          // 保留id最小的那个，删除其他重复项
          const deleteSql = 'DELETE FROM ' + BookingConstants.TABLE_CATEGORY + ' ' +
                            'WHERE type = ? AND name = ? AND id != ?';
          
          // 使用绑定参数执行删除操作
          const bindArgs = [group.type, group.name, group.keepId];
          await this.rdbStore?.executeSql(deleteSql, bindArgs);
          
          console.info(`已清理重复分类: 类型=${group.type}, 名称=${group.name}, 保留ID=${group.keepId}`);
        }
        
        console.info(`共清理了${duplicateGroups.length}组重复分类`);
      } else {
        console.info('未发现重复的分类数据');
      }
    } catch (err) {
      console.error('清理重复分类失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 初始化默认分类
   */
  private async initDefaultCategories(): Promise<void> {
    // 检查分类表是否为空
    const count = await this.getCategoriesCount();
    if (count > 0) {
      console.info('分类表已有数据，跳过初始化默认分类');
      return;
    }
    
    console.info('分类表为空，开始初始化默认分类');
    
    // 收入分类
    const incomeCategories: CategoryOption[] = [
      { type: BookingConstants.INCOME_TYPE, name: '工资', icon: BookingConstants.ICON_SALARY },
      { type: BookingConstants.INCOME_TYPE, name: '奖金', icon: BookingConstants.ICON_BONUS },
      { type: BookingConstants.INCOME_TYPE, name: '兼职', icon: BookingConstants.ICON_PARTTIME },
      { type: BookingConstants.INCOME_TYPE, name: '投资', icon: BookingConstants.ICON_INVESTMENT },
      { type: BookingConstants.INCOME_TYPE, name: '其他', icon: BookingConstants.ICON_MISC }
    ];

    // 支出分类
    const expenseCategories: CategoryOption[] = [
      { type: BookingConstants.EXPENSE_TYPE, name: '餐饮', icon: BookingConstants.ICON_FOOD },
      { type: BookingConstants.EXPENSE_TYPE, name: '购物', icon: BookingConstants.ICON_SHOPPING },
      { type: BookingConstants.EXPENSE_TYPE, name: '交通', icon: BookingConstants.ICON_TRANSPORT },
      { type: BookingConstants.EXPENSE_TYPE, name: '住房', icon: BookingConstants.ICON_HOUSING },
      { type: BookingConstants.EXPENSE_TYPE, name: '娱乐', icon: BookingConstants.ICON_DINING }, 
      { type: BookingConstants.EXPENSE_TYPE, name: '医疗', icon: BookingConstants.ICON_MEDICAL },
      { type: BookingConstants.EXPENSE_TYPE, name: '教育', icon: BookingConstants.ICON_EDUCATION },
      { type: BookingConstants.EXPENSE_TYPE, name: '其他', icon: BookingConstants.ICON_MISC }
    ];

    try {
      // 插入收入分类
      for (const category of incomeCategories) {
        await this.insertCategoryWithIconKey(category.type, category.name, category.icon);
      }
      
      // 插入支出分类
      for (const category of expenseCategories) {
        await this.insertCategoryWithIconKey(category.type, category.name, category.icon);
      }
      
      console.info('初始化默认分类数据完成');
    } catch (err) {
      console.error('初始化默认分类失败：', JSON.stringify(err));
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
      const defaultAccountBook = {
        name: '默认账本',
        type: BookingConstants.ACCOUNT_BOOK_TYPE_DEFAULT,
        balance: 0,
        isDefault: 1,
        icon: BookingConstants.ICON_ACCOUNT_BOOK_DEFAULT
      };
      
      await this.insertAccountBook(defaultAccountBook);
      
      console.info('初始化默认账本数据完成');
    } catch (err) {
      console.error('初始化默认账本失败：', JSON.stringify(err));
    }
  }

  /**
   * 获取分类数量
   */
  private async getCategoriesCount(): Promise<number> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      const sql = 'SELECT COUNT(*) AS count FROM ' + BookingConstants.TABLE_CATEGORY;
      const resultSet = await this.rdbStore?.querySql(sql);
      
      let count = 0;
      if (resultSet && resultSet.goToFirstRow()) {
        count = resultSet.getDouble(resultSet.getColumnIndex('count'));
      }
      
      resultSet?.close();
      return count;
    } catch (err) {
      console.error('Get categories count failed: ' + JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 获取账本数量
   */
  private async getAccountBooksCount(): Promise<number> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      const sql = 'SELECT COUNT(*) AS count FROM ' + BookingConstants.TABLE_ACCOUNT_BOOK;
      const resultSet = await this.rdbStore?.querySql(sql);
      
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
   * 插入分类
   * @param category 分类数据
   */
  public async insertCategory(category: CategoryModel): Promise<number> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      // 根据分类类型和名称获取图标标识符
      const iconKey = this.getIconKeyByTypeAndName(category.type, category.name);
      
      const valuesBucket: dataRdb.ValuesBucket = {
        type: category.type,
        name: category.name,
        icon: iconKey,
        createTime: category.createTime
      };
      
      const rowId = await this.rdbStore?.insert(BookingConstants.TABLE_CATEGORY, valuesBucket);
      return rowId ?? -1;
    } catch (err) {
      console.error('Insert category failed: ' + JSON.stringify(err));
      return -1;
    }
  }

  /**
   * 使用图标标识符插入分类
   * @param type 分类类型
   * @param name 分类名称
   * @param iconKey 图标标识符
   */
  private async insertCategoryWithIconKey(type: number, name: string, iconKey: string): Promise<number> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      const valuesBucket: dataRdb.ValuesBucket = {
        type: type,
        name: name,
        icon: iconKey,
        createTime: new Date().getTime()
      };
      
      const rowId = await this.rdbStore?.insert(BookingConstants.TABLE_CATEGORY, valuesBucket);
      return rowId ?? -1;
    } catch (err) {
      console.error('Insert category failed: ' + JSON.stringify(err));
      return -1;
    }
  }

  /**
   * 插入账本
   * @param accountBook 账本数据
   */
  public async insertAccountBook(accountBook: any): Promise<number> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      const valuesBucket: dataRdb.ValuesBucket = {
        name: accountBook.name,
        type: accountBook.type,
        balance: accountBook.balance,
        isDefault: accountBook.isDefault,
        icon: accountBook.icon,
        createTime: new Date().getTime()
      };
      
      const rowId = await this.rdbStore?.insert(BookingConstants.TABLE_ACCOUNT_BOOK, valuesBucket);
      return rowId ?? -1;
    } catch (err) {
      console.error('Insert account book failed: ' + JSON.stringify(err));
      return -1;
    }
  }

  /**
   * 获取所有分类
   * @param type 分类类型
   */
  public async getAllCategories(type?: number): Promise<CategoryModel[]> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      const predicates = new dataRdb.RdbPredicates(BookingConstants.TABLE_CATEGORY);
      
      if (type !== undefined) {
        predicates.equalTo('type', type);
      }
      
      // 按照创建时间排序
      const resultSet = await this.rdbStore?.query(predicates, ['id', 'type', 'name', 'icon', 'createTime']);
      const categories: CategoryModel[] = [];
      
      if (resultSet) {
        while (resultSet.goToNextRow()) {
          const id = resultSet.getLong(resultSet.getColumnIndex('id'));
          const type = resultSet.getLong(resultSet.getColumnIndex('type'));
          const name = resultSet.getString(resultSet.getColumnIndex('name'));
          const iconStr = resultSet.getString(resultSet.getColumnIndex('icon'));
          const createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));
          
          const category = new CategoryModel(type, name, this.getResourceByKey(iconStr));
          category.id = id;
          category.createTime = createTime;
          
          categories.push(category);
        }
        
        resultSet.close();
      }
      
      return categories;
    } catch (err) {
      console.error('Get categories failed: ' + JSON.stringify(err));
      return [];
    }
  }

  /**
   * 根据ID获取分类
   * @param id 分类ID
   */
  public async getCategoryById(id: number): Promise<CategoryModel | null> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      const predicates = new dataRdb.RdbPredicates(BookingConstants.TABLE_CATEGORY);
      predicates.equalTo('id', id);
      
      const resultSet = await this.rdbStore?.query(predicates);
      let category: CategoryModel | null = null;
      
      if (resultSet && resultSet.goToFirstRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const type = resultSet.getLong(resultSet.getColumnIndex('type'));
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        const iconId = resultSet.getString(resultSet.getColumnIndex('icon'));
        const createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));
        
        category = new CategoryModel(type, name, this.getResourceByKey(iconId), id);
        category.createTime = createTime;
      }
      
      resultSet?.close();
      return category;
    } catch (err) {
      console.error('Query category by id failed: ' + JSON.stringify(err));
      return null;
    }
  }

  /**
   * 添加记录
   * @param record 记录数据
   */
  public async insertRecord(record: RecordModel): Promise<number> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      const valuesBucket: dataRdb.ValuesBucket = {
        type: record.type,
        categoryId: record.categoryId,
        amount: record.amount,
        description: record.description,
        recordTime: record.recordTime,
        accountBookId: record.accountBookId,
        createTime: record.createTime
      };
      
      const rowId = await this.rdbStore?.insert(BookingConstants.TABLE_RECORD, valuesBucket);
      return rowId ?? -1;
    } catch (err) {
      console.error('Insert record failed: ' + JSON.stringify(err));
      return -1;
    }
  }

  /**
   * 删除记录
   * @param id 记录ID
   */
  public async deleteRecord(id: number): Promise<number> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      const predicates = new dataRdb.RdbPredicates(BookingConstants.TABLE_RECORD);
      predicates.equalTo('id', id);
      
      const count = await this.rdbStore?.delete(predicates);
      return count ?? 0;
    } catch (err) {
      console.error('Delete record failed: ' + JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 更新记录
   * @param record 记录数据
   */
  public async updateRecord(record: RecordModel): Promise<number> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      const valuesBucket: dataRdb.ValuesBucket = {
        type: record.type,
        categoryId: record.categoryId,
        amount: record.amount,
        description: record.description,
        recordTime: record.recordTime
      };
      
      const condition = new dataRdb.RdbPredicates(BookingConstants.TABLE_RECORD);
      condition.equalTo('id', record.id);
      
      const rows = await this.rdbStore?.update(valuesBucket, condition);
      return rows ?? 0;
    } catch (err) {
      console.error('Update record failed: ' + JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 获取记录列表
   * @param type 记录类型
   * @param startDate 开始日期
   * @param endDate 结束日期
   */
  public async getRecordsWithCategory(
    type?: number,
    startDate?: number,
    endDate?: number
  ): Promise<RecordWithCategory[]> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      // 构建SQL查询
      let sql = 'SELECT r.*, c.type as c_type, c.name as c_name, c.icon as c_icon ' +
                'FROM ' + BookingConstants.TABLE_RECORD + ' r ' +
                'LEFT JOIN ' + BookingConstants.TABLE_CATEGORY + ' c ' +
                'ON r.categoryId = c.id';
      
      // 条件子句
      const conditions: string[] = [];
      const args: string[] = [];
      
      if (type !== undefined) {
        conditions.push('r.type = ?');
        args.push(type.toString());
      }
      
      if (startDate !== undefined) {
        conditions.push('r.recordTime >= ?');
        args.push(startDate.toString());
      }
      
      if (endDate !== undefined) {
        conditions.push('r.recordTime <= ?');
        args.push(endDate.toString());
      }
      
      if (conditions.length > 0) {
        sql += ' WHERE ' + conditions.join(' AND ');
      }
      
      // 排序
      sql += ' ORDER BY r.recordTime DESC';
      
      // 执行查询
      const resultSet = await this.rdbStore?.querySql(sql, args);
      const records: RecordWithCategory[] = [];
      
      if (resultSet) {
        while (resultSet.goToNextRow()) {
          // 记录信息
          const id = resultSet.getLong(resultSet.getColumnIndex('id'));
          const type = resultSet.getLong(resultSet.getColumnIndex('type'));
          const categoryId = resultSet.getLong(resultSet.getColumnIndex('categoryId'));
          const amount = resultSet.getDouble(resultSet.getColumnIndex('amount'));
          const description = resultSet.getString(resultSet.getColumnIndex('description'));
          const recordTime = resultSet.getLong(resultSet.getColumnIndex('recordTime'));
          const accountBookId = resultSet.getLong(resultSet.getColumnIndex('accountBookId'));
          const createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));
          
          // 类别信息
          const c_name = resultSet.getString(resultSet.getColumnIndex('c_name'));
          let iconString = resultSet.getString(resultSet.getColumnIndex('c_icon'));
          
          // 创建记录对象
          const record = new RecordModel(
            type, categoryId, amount, description, recordTime, accountBookId
          );
          record.id = id;
          record.createTime = createTime;
          
          // 创建类别对象
          const category = new CategoryModel(
            type, c_name, this.getResourceByKey(iconString));
          category.id = categoryId;
          
          // 创建带类别的记录对象
          const recordWithCategory = new RecordWithCategory(record, category);
          records.push(recordWithCategory);
        }
        
        resultSet.close();
      }
      
      return records;
    } catch (err) {
      console.error('Get records with category failed: ' + JSON.stringify(err));
      return [];
    }
  }
  
  /**
   * 获取分类统计
   * @param type 记录类型
   * @param startDate 开始日期
   * @param endDate 结束日期
   */
  public async getStatisticsByCategory(
    type: number,
    startDate?: number,
    endDate?: number
  ): Promise<CategorySummary[]> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      // 构建SQL查询，按类别统计
      let sql = 'SELECT ' +
              'r.categoryId as categoryId, ' +
              'c.name as categoryName, ' +
              'c.icon as icon, ' +
              'SUM(r.amount) as amount ' +
            'FROM ' + BookingConstants.TABLE_RECORD + ' r ' +
            'LEFT JOIN ' + BookingConstants.TABLE_CATEGORY + ' c ' +
            'ON r.categoryId = c.id ' +
            'WHERE r.type = ?';
      
      const args: string[] = [type.toString()];
      
      if (startDate !== undefined) {
        sql += ' AND r.recordTime >= ?';
        args.push(startDate.toString());
      }
      
      if (endDate !== undefined) {
        sql += ' AND r.recordTime <= ?';
        args.push(endDate.toString());
      }
      
      sql += ' GROUP BY r.categoryId ORDER BY amount DESC';
      
      // 执行查询
      const resultSet = await this.rdbStore?.querySql(sql, args);
      const statistics: CategorySummary[] = [];
      
      if (resultSet) {
        while (resultSet.goToNextRow()) {
          const categoryId = resultSet.getLong(resultSet.getColumnIndex('categoryId'));
          const categoryName = resultSet.getString(resultSet.getColumnIndex('categoryName'));
          const iconKey = resultSet.getString(resultSet.getColumnIndex('icon'));
          const amount = resultSet.getDouble(resultSet.getColumnIndex('amount'));
          
          statistics.push({
            categoryId,
            categoryName,
            icon: iconKey,
            amount
          });
        }
        resultSet.close();
      }
      
      return statistics;
    } catch (err) {
      console.error('Query statistics failed: ' + JSON.stringify(err));
      return [];
    }
  }

  /**
   * 获取一段时间内的收支统计
   * @param startDate 开始日期
   * @param endDate 结束日期
   */
  public async getSummary(
    startDate?: number,
    endDate?: number
  ): Promise<SummaryData> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    const summary: SummaryData = { income: 0, expense: 0 };
    
    try {
      for (const type of [BookingConstants.INCOME_TYPE, BookingConstants.EXPENSE_TYPE]) {
        // 构建SQL查询
        let sql = 'SELECT SUM(amount) as total FROM ' + BookingConstants.TABLE_RECORD + 
                  ' WHERE type = ?';
        
        const args: string[] = [type.toString()];
        
        if (startDate !== undefined) {
          sql += ' AND recordTime >= ?';
          args.push(startDate.toString());
        }
        
        if (endDate !== undefined) {
          sql += ' AND recordTime <= ?';
          args.push(endDate.toString());
        }
        
        // 执行查询
        const resultSet = await this.rdbStore?.querySql(sql, args);
        
        if (resultSet && resultSet.goToFirstRow()) {
          const total = resultSet.getDouble(resultSet.getColumnIndex('total')) || 0;
          
          if (type === BookingConstants.INCOME_TYPE) {
            summary.income = total;
          } else {
            summary.expense = total;
          }
        }
        
        resultSet?.close();
      }
      
      return summary;
    } catch (err) {
      console.error('Query summary failed: ' + JSON.stringify(err));
      return summary;
    }
  }

  /**
   * 根据图标标识符获取对应的资源ID
   *
   * @param iconKey 图标标识符
   * @return 资源ID
   */
  getResourceByKey(iconKey: string): Resource {
    switch (iconKey) {
      case BookingConstants.ICON_SALARY:
        return $r('app.media.ic_salary' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_BONUS:
        return $r('app.media.ic_bonus' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_INVESTMENT:
        return $r('app.media.ic_investment' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_PARTTIME:
        return $r('app.media.ic_parttime' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_FOOD:
        return $r('app.media.ic_food' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_TRANSPORT:
        return $r('app.media.ic_transport' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_SHOPPING:
        return $r('app.media.ic_shopping' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_HOUSING:
        return $r('app.media.ic_housing' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_MEDICAL:
        return $r('app.media.ic_medical' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_EDUCATION:
        return $r('app.media.ic_education' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_DINING:
        return $r('app.media.ic_dining' + BookingConstants.CARTOON_NEW_SUFFIX);
      case BookingConstants.ICON_MISC:
      default:
        return $r('app.media.ic_misc' + BookingConstants.CARTOON_NEW_SUFFIX);
    }
  }

  /**
   * 获取图标标识符
   * @param type 分类类型
   * @param name 分类名称
   * @returns 图标标识符
   */
  public  getIconKeyByTypeAndName(type: number, name: string): string {
    // 收入类型的图标映射
    if (type === BookingConstants.INCOME_TYPE) {
      switch (name) {
        case '工资':
          return BookingConstants.ICON_SALARY;
        case '奖金':
          return BookingConstants.ICON_BONUS;
        case '兼职':
          return BookingConstants.ICON_PARTTIME;
        case '投资':
          return BookingConstants.ICON_INVESTMENT;
        default:
          return BookingConstants.ICON_MISC;
      }
    }
    
    // 支出类型的图标映射
    if (type === BookingConstants.EXPENSE_TYPE) {
      switch (name) {
        case '餐饮':
          return BookingConstants.ICON_FOOD;
        case '购物':
          return BookingConstants.ICON_SHOPPING;
        case '交通':
          return BookingConstants.ICON_TRANSPORT;
        case '住房':
          return BookingConstants.ICON_HOUSING;
        case '娱乐':
          return BookingConstants.ICON_DINING;
        case '医疗':
          return BookingConstants.ICON_MEDICAL;
        case '教育':
          return BookingConstants.ICON_EDUCATION;
        default:
          return BookingConstants.ICON_MISC;
      }
    }
    
    return BookingConstants.ICON_MISC;
  }

  /**
   * 获取所有账本
   */
  public async getAllAccountBooks(): Promise<AccountBookModel[]> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      // 查询所有账本，默认账本始终排在第一位
      const sql = 'SELECT * FROM ' + BookingConstants.TABLE_ACCOUNT_BOOK + ' ORDER BY isDefault DESC, id ASC';
      const resultSet = await this.rdbStore?.querySql(sql);
      
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
          
          const icon = this.getResourceByKey(iconStr);
          
          const accountBook = new AccountBookModel(name, type, balance, icon, isDefault, id);
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
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      const sql = 'SELECT * FROM ' + BookingConstants.TABLE_ACCOUNT_BOOK + ' WHERE isDefault = 1 LIMIT 1';
      const resultSet = await this.rdbStore?.querySql(sql);
      
      let accountBook: AccountBookModel | null = null;
      
      if (resultSet && resultSet.goToFirstRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        const type = resultSet.getLong(resultSet.getColumnIndex('type'));
        const balance = resultSet.getDouble(resultSet.getColumnIndex('balance'));
        const isDefault = resultSet.getLong(resultSet.getColumnIndex('isDefault'));
        const iconStr = resultSet.getString(resultSet.getColumnIndex('icon'));
        const createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));
        
        const icon = this.getResourceByKey(iconStr);
        
        accountBook = new AccountBookModel(name, type, balance, icon, isDefault, id);
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
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    if (!accountId) {
      return this.getDefaultAccountBook();
    }
    
    try {
      const sql = 'SELECT * FROM ' + BookingConstants.TABLE_ACCOUNT_BOOK + ' WHERE id = ? LIMIT 1';
      const resultSet = await this.rdbStore?.querySql(sql, [accountId]);
      
      let accountBook: AccountBookModel | null = null;
      
      if (resultSet && resultSet.goToFirstRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        const type = resultSet.getLong(resultSet.getColumnIndex('type'));
        const balance = resultSet.getDouble(resultSet.getColumnIndex('balance'));
        const isDefault = resultSet.getLong(resultSet.getColumnIndex('isDefault'));
        const iconStr = resultSet.getString(resultSet.getColumnIndex('icon'));
        const createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));
        
        const icon = this.getResourceByKey(iconStr);
        
        accountBook = new AccountBookModel(name, type, balance, icon, isDefault, id);
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
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
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
      
      const count = await this.rdbStore?.update(valuesBucket, predicates);
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
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      // 先将所有账本设置为非默认
      let valuesBucket: dataRdb.ValuesBucket = {
        isDefault: BookingConstants.ACCOUNT_NOT_DEFAULT
      };
      
      let predicates = new dataRdb.RdbPredicates(BookingConstants.TABLE_ACCOUNT_BOOK);
      await this.rdbStore?.update(valuesBucket, predicates);
      
      // 设置指定账本为默认
      valuesBucket = {
        isDefault: BookingConstants.ACCOUNT_IS_DEFAULT
      };
      
      predicates = new dataRdb.RdbPredicates(BookingConstants.TABLE_ACCOUNT_BOOK);
      predicates.equalTo('id', accountId);
      
      const count = await this.rdbStore?.update(valuesBucket, predicates);
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
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      // 检查是否为默认账本，不允许删除默认账本
      const accountBook = await this.getAccountBookById(accountId);
      if (!accountBook || accountBook.isDefault === BookingConstants.ACCOUNT_IS_DEFAULT) {
        console.error('不能删除默认账本');
        return false;
      }
      
      const predicates = new dataRdb.RdbPredicates(BookingConstants.TABLE_ACCOUNT_BOOK);
      predicates.equalTo('id', accountId);
      
      const count = await this.rdbStore?.delete(predicates);
      return count !== undefined && count > 0;
    } catch (err) {
      console.error('删除账本失败: ' + JSON.stringify(err));
      return false;
    }
  }
  
  /**
   * 插入转账记录
   * @param transfer 转账记录
   */
  public async insertTransfer(transfer: TransferModel): Promise<number> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      const valuesBucket: dataRdb.ValuesBucket = {
        fromAccountId: transfer.fromAccountId,
        toAccountId: transfer.toAccountId,
        amount: transfer.amount,
        description: transfer.description,
        relatedId: transfer.relatedId || null,
        transferTime: transfer.transferTime,
        createTime: transfer.createTime
      };
      
      const rowId = await this.rdbStore?.insert(BookingConstants.TABLE_TRANSFER, valuesBucket);
      return rowId !== undefined ? rowId : -1;
    } catch (err) {
      console.error('插入转账记录失败: ' + JSON.stringify(err));
      return -1;
    }
  }

  /**
   * 获取转账记录列表
   * @param accountId 账本ID（可选）
   * @param startDate 开始日期（可选）
   * @param endDate 结束日期（可选）
   */
  public async getTransferRecords(
    accountId?: number,
    startDate?: number,
    endDate?: number
  ): Promise<TransferModel[]> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      let sql = 'SELECT * FROM ' + BookingConstants.TABLE_TRANSFER;
      const params: any[] = [];
      
      // 条件子句
      const conditions: string[] = [];
      
      if (accountId) {
        conditions.push('(fromAccountId = ? OR toAccountId = ?)');
        params.push(accountId, accountId);
      }
      
      if (startDate) {
        conditions.push('transferTime >= ?');
        params.push(startDate);
      }
      
      if (endDate) {
        conditions.push('transferTime <= ?');
        params.push(endDate);
      }
      
      if (conditions.length > 0) {
        sql += ' WHERE ' + conditions.join(' AND ');
      }
      
      // 排序
      sql += ' ORDER BY transferTime DESC';
      
      const resultSet = await this.rdbStore?.querySql(sql, params);
      const transfers: TransferModel[] = [];
      
      if (resultSet) {
        while (resultSet.goToNextRow()) {
          const id = resultSet.getLong(resultSet.getColumnIndex('id'));
          const fromAccountId = resultSet.getLong(resultSet.getColumnIndex('fromAccountId'));
          const toAccountId = resultSet.getLong(resultSet.getColumnIndex('toAccountId'));
          const amount = resultSet.getDouble(resultSet.getColumnIndex('amount'));
          const description = resultSet.getString(resultSet.getColumnIndex('description'));
          const relatedId = resultSet.getLong(resultSet.getColumnIndex('relatedId'));
          const transferTime = resultSet.getLong(resultSet.getColumnIndex('transferTime'));
          const createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));
          
          const transfer = new TransferModel(
            fromAccountId,
            toAccountId,
            amount,
            description,
            transferTime,
            relatedId > 0 ? relatedId : undefined,
            id
          );
          transfer.createTime = createTime;
          
          transfers.push(transfer);
        }
        
        resultSet.close();
      }
      
      return transfers;
    } catch (err) {
      console.error('获取转账记录列表失败: ' + JSON.stringify(err));
      return [];
    }
  }

  /**
   * 执行转账操作
   * @param fromAccountId 转出账本ID
   * @param toAccountId 转入账本ID
   * @param amount 转账金额
   * @param description 转账描述（可选）
   * @param transferTime 转账时间（可选，默认当前时间）
   */
  public async executeTransfer(
    fromAccountId: number,
    toAccountId: number,
    amount: number,
    description: string = '',
    transferTime: number = new Date().getTime()
  ): Promise<boolean> {
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    if (fromAccountId === toAccountId) {
      console.error('不能转账到相同的账本');
      return false;
    }
    
    try {
      // 开始事务
      await this.rdbStore?.beginTransaction();
      
      // 1. 插入转账记录
      const transferOut = new TransferModel(
        fromAccountId,
        toAccountId,
        amount,
        description,
        transferTime
      );
      
      const transferOutId = await this.insertTransfer(transferOut);
      if (transferOutId <= 0) {
        await this.rdbStore?.rollBack();
        return false;
      }
      
      // 2. 更新转出账本余额
      const updateFromResult = await this.updateAccountBalance(fromAccountId, -amount);
      if (!updateFromResult) {
        await this.rdbStore?.rollBack();
        return false;
      }
      
      // 3. 更新转入账本余额
      const updateToResult = await this.updateAccountBalance(toAccountId, amount);
      if (!updateToResult) {
        await this.rdbStore?.rollBack();
        return false;
      }
      
      // 提交事务
      await this.rdbStore?.commit();
      
      return true;
    } catch (err) {
      console.error('执行转账操作失败: ' + JSON.stringify(err));
      // 回滚事务
      if (this.rdbStore) {
        await this.rdbStore.rollBack();
      }
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
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      let sql = `SELECT r.*, c.name as categoryName, c.icon as categoryIcon, c.type as categoryType 
                FROM ${BookingConstants.TABLE_RECORD} r 
                LEFT JOIN ${BookingConstants.TABLE_CATEGORY} c 
                ON r.categoryId = c.id`;
      
      const params: any[] = [];
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
      
      const resultSet = await this.rdbStore?.querySql(sql, params);
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
            this.getResourceByKey(categoryIcon),
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
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    const summary: SummaryData = {
      income: 0,
      expense: 0
    };
    
    try {
      let sql = `SELECT type, SUM(amount) as total 
                FROM ${BookingConstants.TABLE_RECORD} 
                WHERE accountBookId = ?`;
      
      const params: any[] = [accountBookId];
      
      if (startDate) {
        sql += ' AND recordTime >= ?';
        params.push(startDate);
      }
      
      if (endDate) {
        sql += ' AND recordTime <= ?';
        params.push(endDate);
      }
      
      sql += ' GROUP BY type';
      
      const resultSet = await this.rdbStore?.querySql(sql, params);
      
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
    if (!this.rdbStore) {
      await this.initDatabase();
    }
    
    try {
      let sql = `SELECT r.categoryId, c.name as categoryName, c.icon as categoryIcon, SUM(r.amount) as total 
                FROM ${BookingConstants.TABLE_RECORD} r 
                LEFT JOIN ${BookingConstants.TABLE_CATEGORY} c 
                ON r.categoryId = c.id 
                WHERE r.type = ? AND r.accountBookId = ?`;
      
      const params: any[] = [type, accountBookId];
      
      if (startDate) {
        sql += ' AND r.recordTime >= ?';
        params.push(startDate);
      }
      
      if (endDate) {
        sql += ' AND r.recordTime <= ?';
        params.push(endDate);
      }
      
      sql += ' GROUP BY r.categoryId ORDER BY total DESC';
      
      const resultSet = await this.rdbStore?.querySql(sql, params);
      
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
