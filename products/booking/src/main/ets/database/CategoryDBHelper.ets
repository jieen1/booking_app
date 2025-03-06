import dataRdb from '@ohos.data.relationalStore';
import { BookingConstants } from '../constants/BookingConstants';
import { CategoryModel, CategoryOption, DuplicateCategoryGroup } from '../model/CategoryModel';
import { CategorySummary } from '../model/SummaryModel';
import { IconUtils } from '../utils/IconUtils';
import { DBConnectionHolder } from './DBConnectionHolder';

/**
 * 分类相关数据库帮助类
 */
export class CategoryDBHelper {
  private connection: DBConnectionHolder | null = null;
  private static instance: CategoryDBHelper = new CategoryDBHelper();


  constructor() {
    this.initDB()
  }
  /**
   * 获取实例
   * @returns DBHelper实例
   */
  public static getInstance(): CategoryDBHelper {
    return CategoryDBHelper.instance;
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
      // 确保分类表存在
      await this.connection.executeSql(
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
    try {
      console.info('开始清理重复的分类数据');

      // 查询所有分类，按照type和name分组，找出重复的项
      const sql = 'SELECT MIN(id) as keep_id, type, name, COUNT(*) as count ' +
        'FROM ' + BookingConstants.TABLE_CATEGORY + ' ' +
        'GROUP BY type, name ' +
        'HAVING COUNT(*) > 1';

      const resultSet = await this.connection?.querySql(sql);
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
          const bindArgs: (string | number)[] = [group.type, group.name, group.keepId];
          await this.connection?.executeSql(deleteSql, bindArgs);

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

    try {
      const sql = 'SELECT COUNT(*) AS count FROM ' + BookingConstants.TABLE_CATEGORY;
      const resultSet = await this.connection?.querySql(sql);

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
    try {
      // 根据分类类型和名称获取图标标识符
      const iconKey = IconUtils.getIconKeyByTypeAndName(category.type, category.name);

      const valuesBucket: dataRdb.ValuesBucket = {
        type: category.type,
        name: category.name,
        icon: iconKey,
        createTime: category.createTime
      };

      const rowId = await this.connection?.insert(BookingConstants.TABLE_CATEGORY, valuesBucket);
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

    try {
      const valuesBucket: dataRdb.ValuesBucket = {
        type: type,
        name: name,
        icon: iconKey,
        createTime: new Date().getTime()
      };

      const rowId = await this.connection?.insert(BookingConstants.TABLE_CATEGORY, valuesBucket);
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

    try {
      const predicates = new dataRdb.RdbPredicates(BookingConstants.TABLE_CATEGORY);

      if (type !== undefined) {
        predicates.equalTo('type', type);
      }

      // 按照创建时间排序
      const resultSet = await this.connection?.query(predicates, ['id', 'type', 'name', 'icon', 'createTime']);
      const categories: CategoryModel[] = [];

      if (resultSet) {
        while (resultSet.goToNextRow()) {
          const id = resultSet.getLong(resultSet.getColumnIndex('id'));
          const type = resultSet.getLong(resultSet.getColumnIndex('type'));
          const name = resultSet.getString(resultSet.getColumnIndex('name'));
          const iconStr = resultSet.getString(resultSet.getColumnIndex('icon'));
          const createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));

          const category = new CategoryModel(type, name, IconUtils.getResourceByKey(iconStr));
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

    try {
      const predicates = new dataRdb.RdbPredicates(BookingConstants.TABLE_CATEGORY);
      predicates.equalTo('id', id);

      const resultSet = await this.connection?.query(predicates);
      let category: CategoryModel | null = null;

      if (resultSet && resultSet.goToFirstRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const type = resultSet.getLong(resultSet.getColumnIndex('type'));
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        const iconId = resultSet.getString(resultSet.getColumnIndex('icon'));
        const createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));

        category = new CategoryModel(type, name, IconUtils.getResourceByKey(iconId), id);
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
   * 获取分类统计
   * @param type 记录类型
   * @param startDate 开始日期
   * @param endDate 结束日期
   */
  public async getStatisticsByCategory(
    type: number,
    startDate?: number,
    endDate?: number,
    accountId?: number
  ): Promise<CategorySummary[]> {

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

      const args: (string | number)[] = [type.toString()];

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
      const resultSet = await this.connection?.querySql(sql, args);
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

}
