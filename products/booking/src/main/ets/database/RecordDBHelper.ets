import dataRdb from '@ohos.data.relationalStore';
import { BookingConstants } from '../constants/BookingConstants';
import { CategoryModel } from '../model/CategoryModel';
import { RecordModel } from '../model/RecordModel';
import { RecordWithCategory } from '../model/RecordWithCategory';
import { SummaryData } from '../model/SummaryModel';
import { IconUtils } from '../utils/IconUtils';
import { DBConnectionHolder } from './DBConnectionHolder';


/**
 * 数据库帮助类
 */
export class RecordDBHelper {
  private connection: DBConnectionHolder | null = null;
  private static instance: RecordDBHelper = new RecordDBHelper();

  constructor() {
    this.initDB()
  }

  /**
   * 获取实例
   * @returns DBHelper实例
   */
  public static getInstance(): RecordDBHelper {
    return RecordDBHelper.instance;
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

      // 确保记录表存在
      await this.connection.executeSql(
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

      return true;
    } catch (err) {
      console.error('Init database failed: ' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * 添加记录
   * @param record 记录数据
   */
  public async insertRecord(record: RecordModel): Promise<number> {

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

      const rowId = await this.connection?.insert(BookingConstants.TABLE_RECORD, valuesBucket);
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

    try {
      const predicates = new dataRdb.RdbPredicates(BookingConstants.TABLE_RECORD);
      predicates.equalTo('id', id);

      const count = await this.connection?.delete(predicates);
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

      const rows = await this.connection?.update(valuesBucket, condition);
      return rows ?? 0;
    } catch (err) {
      console.error('Update record failed: ' + JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 获取记录列表
   * @param accountBookId 账本ID
   * @param type 记录类型
   * @param startDate 开始日期
   * @param endDate 结束日期
   */
  public async getRecordsWithCategory(
    accountBookId?: number,
    type?: number,
    startDate?: number,
    endDate?: number
  ): Promise<RecordWithCategory[]> {

    try {
      // 构建SQL查询
      let sql = 'SELECT r.*, c.type as c_type, c.name as c_name, c.icon as c_icon ' +
        'FROM ' + BookingConstants.TABLE_RECORD + ' r ' +
        'LEFT JOIN ' + BookingConstants.TABLE_CATEGORY + ' c ' +
        'ON r.categoryId = c.id';

      // 条件子句
      const conditions: string[] = [];
      const args: (string | number)[] = [];

      if (accountBookId !== undefined) {
        conditions.push('r.accountBookId = ?');
        args.push(accountBookId.toString());
      }

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
      const resultSet = await this.connection?.querySql(sql, args);
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
            type, categoryId, amount, description, recordTime, accountBookId, createTime, id
          );

          // 创建类别对象
          const category = new CategoryModel(
            type, c_name, IconUtils.getResourceByKey(iconString));
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
   * 获取一段时间内的收支统计
   * @param startDate 开始日期
   * @param endDate 结束日期
   */
  public async getSummary(
    startDate?: number,
    endDate?: number,
    accountId?: number
  ): Promise<SummaryData> {
    const summary: SummaryData = { income: 0, expense: 0 };

    try {
      for (const type of [BookingConstants.INCOME_TYPE, BookingConstants.EXPENSE_TYPE]) {
        // 构建SQL查询
        let sql = 'SELECT SUM(amount) as total FROM ' + BookingConstants.TABLE_RECORD +
          ' WHERE type = ?';

        const args: (string | number)[] = [type.toString()];

        if (startDate !== undefined) {
          sql += ' AND recordTime >= ?';
          args.push(startDate.toString());
        }

        if (endDate !== undefined) {
          sql += ' AND recordTime <= ?';
          args.push(endDate.toString());
        }

        // 执行查询
        const resultSet = await this.connection?.querySql(sql, args);

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
}
