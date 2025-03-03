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

      // 清理重复的分类数据
      try {
        await this.cleanDuplicateCategories();
      } catch (err) {
        console.error('清理重复分类时出错，继续初始化：' + JSON.stringify(err));
      }
      
      // 初始化默认分类数据（只在分类表为空时执行）
      await this.initDefaultCategories();
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
          const createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));
          
          // 类别信息
          const c_name = resultSet.getString(resultSet.getColumnIndex('c_name'));
          let iconString = resultSet.getString(resultSet.getColumnIndex('c_icon'));
          
          // 创建记录对象
          const record = new RecordModel(
            type, categoryId, amount, description, recordTime
          );
          record.id = id;
          record.createTime = createTime;
          
          // 创建类别对象
          const category = new CategoryModel(
            type, c_name, this.getResourceByKey(iconString)
          );
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
}
