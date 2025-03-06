import dataRdb from '@ohos.data.relationalStore';
import { BookingConstants } from '../constants/BookingConstants';
import { ValueType } from '@kit.ArkData';

/**
 * 数据库配置接口
 */
interface DBConfig {
  name: string;
  securityLevel: dataRdb.SecurityLevel;
}


export class DBConnectionHolder {
  private rdbStore: dataRdb.RdbStore | null = null;
  private static instance: DBConnectionHolder = new DBConnectionHolder();

  /**
   * 获取实例
   * @returns DBHelper实例
   */
  public static getInstance(): DBConnectionHolder {
    return DBConnectionHolder.instance;
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

      return true;
    } catch (err) {
      console.error('Init database failed: ' + JSON.stringify(err));
      return false;
    }
  }

  public async executeSql(sql: string, bindArgs?: Array<ValueType>) {
    if (!this.rdbStore) {
      await this.initDB();
    }
    this.rdbStore?.executeSql(sql, bindArgs)
  }

  public async insert(tableName: string, valuesBucket: dataRdb.ValuesBucket) {
    if (!this.rdbStore) {
      await this.initDB();
    }
    return this.rdbStore?.insert(tableName, valuesBucket);
  }

  public async delete(predicates: dataRdb.RdbPredicates) {
    if (!this.rdbStore) {
      await this.initDB();
    }
    return this.rdbStore?.delete(predicates);
  }

  public async update(valuesBucket: dataRdb.ValuesBucket, predicates: dataRdb.RdbPredicates) {
    if (!this.rdbStore) {
      await this.initDB();
    }
    return this.rdbStore?.update(valuesBucket, predicates);
  }

  public async querySql(sql: string, args?: Array<string | number>) {
    if (!this.rdbStore) {
      await this.initDB();
    }
    return this.rdbStore?.querySql(sql, args);
  }

  public async query(predicates: dataRdb.RdbPredicates, columns?: Array<string>) {
    if (!this.rdbStore) {
      await this.initDB();
    }
    return this.rdbStore?.query(predicates, columns);
  }

  public async beginTransaction() {
    if (!this.rdbStore) {
      await this.initDB();
    }
    return this.rdbStore?.beginTransaction();
  }

  public async rollBack() {
    if (!this.rdbStore) {
      await this.initDB();
    }
    return this.rdbStore?.rollBack();
  }

  public async commit() {
    if (!this.rdbStore) {
      await this.initDB();
    }
    return this.rdbStore?.commit();
  }
}