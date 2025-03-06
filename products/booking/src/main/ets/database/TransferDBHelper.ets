import dataRdb from '@ohos.data.relationalStore';
import { BookingConstants } from '../constants/BookingConstants';
import { DBConnectionHolder } from './DBConnectionHolder';
import { TransferModel } from '../model/TransferModel';
import { BookDBHelper } from './BookDBHelper';


/**
 * 数据库帮助类
 */
export class TransferDBHelper {
  private connection: DBConnectionHolder | null = null;
  private static instance: TransferDBHelper = new TransferDBHelper();

  constructor() {
    this.initDB()
  }

  /**
   * 获取实例
   * @returns DBHelper实例
   */
  public static getInstance(): TransferDBHelper {
    return TransferDBHelper.instance;
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

      // 确保转账表存在
      await this.connection.executeSql(
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

      return true;
    } catch (err) {
      console.error('Init database failed: ' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * 插入转账记录
   * @param transfer 转账记录
   */
  public async insertTransfer(transfer: TransferModel): Promise<number> {

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

      const rowId = await this.connection?.insert(BookingConstants.TABLE_TRANSFER, valuesBucket);
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

    try {
      let sql = 'SELECT * FROM ' + BookingConstants.TABLE_TRANSFER;
      const params: (string | number)[] = [];

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

      const resultSet = await this.connection?.querySql(sql, params);
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

    if (fromAccountId === toAccountId) {
      console.error('不能转账到相同的账本');
      return false;
    }

    try {
      // 开始事务
      await this.connection?.beginTransaction();

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
        await this.connection?.rollBack();
        return false;
      }

      // 2. 更新转出账本余额
      const updateFromResult = await BookDBHelper.getInstance().updateAccountBalance(fromAccountId, -amount);
      if (!updateFromResult) {
        await this.connection?.rollBack();
        return false;
      }

      // 3. 更新转入账本余额
      const updateToResult = await BookDBHelper.getInstance().updateAccountBalance(toAccountId, amount);
      if (!updateToResult) {
        await this.connection?.rollBack();
        return false;
      }

      // 提交事务
      await this.connection?.commit();

      return true;
    } catch (err) {
      console.error('执行转账操作失败: ' + JSON.stringify(err));
      // 回滚事务
      if (this.connection) {
        await this.connection.rollBack();
      }
      return false;
    }
  }
}
