import dataRdb from '@ohos.data.relationalStore';
import { DBConnectionHolder } from './DBConnectionHolder';
import { InvestmentType } from '../model/InvestmentBookModel';
import { InvestmentAssetModel } from '../model/InvestmentAssetModel';
import { DatabaseError } from '../errors/DatabaseError';

/**
 * 投资资产数据库记录接口
 */
interface IInvestmentAssetRecord {
  id: number;
  bookId: number;
  code: string;
  name: string;
  assetType: number;
  purchasePrice: number;
  currentPrice: number;
  quantity: number;
  cost: number;
  marketValue: number;
  profit: number;
  profitRate: number;
  purchaseDate: number;
  notes: string;
  updateTime: number;
  createTime: number;
}

/**
 * 投资利润接口
 */
export interface InvestmentProfit {
  profit: number;
  profitRate: number;
}

/**
 * 资产类型分布接口
 */
export interface AssetTypeDistribution {
  assetType: InvestmentType;
  totalValue: number;
  proportion: number;
}

/**
 * 投资资产数据库帮助类
 */
export class InvestmentAssetDBHelper {
  /** 投资资产表名 */
  static readonly TABLE_INVESTMENT_ASSET: string = 'investment_asset';
  
  /** 单例实例 */
  private static instance: InvestmentAssetDBHelper = new InvestmentAssetDBHelper();
  
  /** 数据库连接 */
  private connection: DBConnectionHolder | null = null;

  constructor() {
    this.initialize()
  }

  /**
   * 获取实例
   * @returns InvestmentAssetDBHelper实例
   */
  static getInstance(): InvestmentAssetDBHelper {
    return InvestmentAssetDBHelper.instance;
  }
  
  /**
   * 初始化数据库
   */
  public async initialize(): Promise<boolean> {
    try {
      // 获取数据库连接
      this.connection = DBConnectionHolder.getInstance();
      
      // 创建投资资产表
      await this.createInvestmentAssetTable();
      
      console.info('初始化投资资产数据库成功');
      return true;
    } catch (error) {
      console.error('初始化投资资产数据库失败', error);
      throw new DatabaseError('初始化投资资产数据库失败', '初始化', 1001);
    }
  }
  
  /**
   * 创建投资资产表
   */
  private async createInvestmentAssetTable(): Promise<void> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '创建表', 1002);
      }
      
      // 创建投资资产表
      await this.connection.executeSql(
        'CREATE TABLE IF NOT EXISTS ' + InvestmentAssetDBHelper.TABLE_INVESTMENT_ASSET + ' ' +
        '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'bookId INTEGER, ' +  // 账本ID
        'code TEXT, ' +       // 股票/基金代码
        'name TEXT, ' +       // 股票/基金名称
        'assetType INTEGER, ' + // 资产类型
        'purchasePrice REAL, ' + // 购入价格
        'currentPrice REAL, ' +  // 当前价格
        'quantity REAL, ' +      // 持有数量
        'cost REAL, ' +          // 持仓成本
        'marketValue REAL, ' +   // 当前市值
        'profit REAL, ' +        // 收益金额
        'profitRate REAL, ' +    // 收益率
        'purchaseDate INTEGER, ' + // 购买日期
        'notes TEXT, ' +         // 备注
        'updateTime INTEGER, ' +  // 更新时间
        'createTime INTEGER)', // 创建时间
        []
      );
      
      console.info('创建投资资产表成功');
    } catch (error) {
      console.error('创建投资资产表失败', error);
      throw new DatabaseError('创建投资资产表失败', '创建表', 1003);
    }
  }
  
  /**
   * 添加投资资产
   * @param asset 投资资产对象
   * @returns 新增的资产ID
   */
  async addInvestmentAsset(asset: InvestmentAssetModel): Promise<number> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '添加资产', 2001);
      }
      
      // 准备数据
      const valuesBucket: dataRdb.ValuesBucket = {
        bookId: asset.bookId,
        code: asset.code,
        name: asset.name,
        assetType: asset.assetType,
        purchasePrice: asset.purchasePrice,
        currentPrice: asset.currentPrice,
        quantity: asset.quantity,
        cost: asset.cost,
        marketValue: asset.marketValue,
        profit: asset.profit,
        profitRate: asset.profitRate,
        purchaseDate: 0, // 默认值
        notes: '', // 默认值
        updateTime: asset.updateTime,
        createTime: asset.createTime
      };
      
      // 插入数据
      const rowId = await this.connection.insert(InvestmentAssetDBHelper.TABLE_INVESTMENT_ASSET, valuesBucket);
      
      if (rowId === undefined) {
        throw new DatabaseError('添加投资资产失败', '添加资产', 2002);
      }
      
      console.info('添加投资资产成功:', rowId);
      return rowId;
    } catch (error) {
      console.error('添加投资资产失败', error);
      throw new DatabaseError('添加投资资产失败', '添加资产', 2003);
    }
  }
  
  /**
   * 更新投资资产
   * @param asset 投资资产对象
   * @returns 是否更新成功
   */
  async updateInvestmentAsset(asset: InvestmentAssetModel): Promise<boolean> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '更新资产', 3001);
      }
      
      if (asset.id === undefined) {
        throw new DatabaseError('资产ID不能为空', '更新资产', 3002);
      }
      
      // 准备更新数据
      const valuesBucket: dataRdb.ValuesBucket = {
        name: asset.name,
        code: asset.code,
        assetType: asset.assetType,
        purchasePrice: asset.purchasePrice,
        currentPrice: asset.currentPrice,
        quantity: asset.quantity,
        cost: asset.cost,
        marketValue: asset.marketValue,
        profit: asset.profit,
        profitRate: asset.profitRate,
        updateTime: asset.updateTime
      };
      
      // 构建谓词
      const predicates = new dataRdb.RdbPredicates(InvestmentAssetDBHelper.TABLE_INVESTMENT_ASSET);
      predicates.equalTo('id', asset.id);
      
      // 更新数据
      const result = await this.connection.update(valuesBucket, predicates);
      
      console.info('更新投资资产成功, 更新数量:', result);
      return result !== undefined && result > 0;
    } catch (error) {
      console.error('更新投资资产失败', error);
      throw new DatabaseError('更新投资资产失败', '更新资产', 3003);
    }
  }
  
  /**
   * 删除投资资产
   * @param assetId 资产ID
   * @returns 是否删除成功
   */
  async deleteInvestmentAsset(assetId: number): Promise<boolean> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '删除资产', 4001);
      }
      
      // 构建谓词
      const predicates = new dataRdb.RdbPredicates(InvestmentAssetDBHelper.TABLE_INVESTMENT_ASSET);
      predicates.equalTo('id', assetId);
      
      // 删除数据
      const result = await this.connection.delete(predicates);
      
      if (result === undefined) {
        console.info('删除投资资产结果为undefined');
        return false;
      }
      
      console.info('删除投资资产成功, 删除数量:', result);
      return result > 0;
    } catch (error) {
      console.error('删除投资资产失败', error);
      throw new DatabaseError('删除投资资产失败', '删除资产', 4002);
    }
  }
  
  /**
   * 根据ID获取投资资产
   * @param assetId 资产ID
   * @returns 投资资产对象
   */
  async getInvestmentAssetById(assetId: number): Promise<InvestmentAssetModel | null> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '获取资产', 5001);
      }
      
      // 构建谓词
      const predicates = new dataRdb.RdbPredicates(InvestmentAssetDBHelper.TABLE_INVESTMENT_ASSET);
      predicates.equalTo('id', assetId);
      
      // 查询数据
      const resultSet = await this.connection.query(predicates, undefined);
      
      if (!resultSet) {
        return null;
      }
      
      if (resultSet.rowCount <= 0) {
        resultSet.close();
        return null;
      }
      
      if (resultSet.goToFirstRow()) {
        const asset = this.buildAssetFromResultSet(resultSet);
        resultSet.close();
        return asset;
      }
      
      resultSet.close();
      return null;
    } catch (error) {
      console.error('获取投资资产失败', error);
      throw new DatabaseError('获取投资资产失败', '获取资产', 5002);
    }
  }
  
  /**
   * 获取账本的投资资产列表
   * @param bookId 账本ID
   * @returns 投资资产列表
   */
  async getAssetsByBookId(bookId: number): Promise<InvestmentAssetModel[]> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '获取资产列表', 6001);
      }
      
      // 构建谓词
      const predicates = new dataRdb.RdbPredicates(InvestmentAssetDBHelper.TABLE_INVESTMENT_ASSET);
      predicates.equalTo('bookId', bookId);
      
      // 查询数据
      const resultSet = await this.connection.query(predicates, undefined);
      const assets: InvestmentAssetModel[] = [];
      
      if (!resultSet) {
        return assets;
      }
      
      while (resultSet.goToNextRow()) {
        const asset = this.buildAssetFromResultSet(resultSet);
        assets.push(asset);
      }
      
      resultSet.close();
      
      return assets;
    } catch (error) {
      console.error('获取投资资产列表失败', error);
      throw new DatabaseError('获取投资资产列表失败', '获取资产列表', 6002);
    }
  }
  
  /**
   * 获取账本的投资收益
   * @param bookId 账本ID
   * @returns 投资收益对象
   */
  async getInvestmentProfit(bookId: number): Promise<InvestmentProfit> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '获取收益', 7001);
      }
      
      // 构建谓词
      const predicates = new dataRdb.RdbPredicates(InvestmentAssetDBHelper.TABLE_INVESTMENT_ASSET);
      predicates.equalTo('bookId', bookId);
      
      // 查询数据
      const resultSet = await this.connection.query(predicates, undefined);
      
      if (!resultSet) {
        return { profit: 0, profitRate: 0 };
      }
      
      let totalCost = 0;
      let totalMarketValue = 0;
      
      while (resultSet.goToNextRow()) {
        totalCost += resultSet.getDouble(resultSet.getColumnIndex('cost'));
        totalMarketValue += resultSet.getDouble(resultSet.getColumnIndex('marketValue'));
      }
      
      resultSet.close();
      
      const profit = Number((totalMarketValue - totalCost).toFixed(2));
      const profitRate = totalCost > 0 ? Number(((profit / totalCost) * 100).toFixed(2)) : 0;
      
      return { profit, profitRate };
    } catch (error) {
      console.error('获取投资收益失败', error);
      throw new DatabaseError('获取投资收益失败', '获取收益', 7002);
    }
  }
  
  /**
   * 获取资产类型分布
   * @param bookId 账本ID
   * @returns 资产类型分布列表
   */
  async getAssetTypeDistribution(bookId: number): Promise<Map<InvestmentType, number>> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '获取资产类型分布', 8001);
      }
      
      // 构建谓词
      const predicates = new dataRdb.RdbPredicates(InvestmentAssetDBHelper.TABLE_INVESTMENT_ASSET);
      predicates.equalTo('bookId', bookId);
      
      // 查询数据
      const resultSet = await this.connection.query(predicates, undefined);
      
      // 按类型统计市值
      const typeMap = new Map<InvestmentType, number>();
      
      if (!resultSet) {
        return typeMap;
      }
      
      let totalValue = 0;
      
      while (resultSet.goToNextRow()) {
        // 根据数据库字段类型使用正确的获取方法 - 使用getLong替代getInt
        const assetTypeValue = resultSet.getLong(resultSet.getColumnIndex('assetType'));
        // 转换为InvestmentType枚举
        const assetType: InvestmentType = assetTypeValue as InvestmentType;
        const marketValue = resultSet.getDouble(resultSet.getColumnIndex('marketValue'));
        
        const currentValue = typeMap.get(assetType) || 0;
        typeMap.set(assetType, currentValue + marketValue);
        totalValue += marketValue;
      }
      
      resultSet.close();
      
      return typeMap;
    } catch (error) {
      console.error('获取资产类型分布失败', error);
      throw new DatabaseError('获取资产类型分布失败', '获取资产类型分布', 8002);
    }
  }
  
  /**
   * 搜索投资资产
   * @param bookId 账本ID
   * @param keyword 搜索关键词
   * @returns 投资资产列表
   */
  async searchInvestmentAssets(bookId: number, keyword: string | undefined): Promise<InvestmentAssetModel[]> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '搜索资产', 9001);
      }
      
      // 构建谓词
      const predicates = new dataRdb.RdbPredicates(InvestmentAssetDBHelper.TABLE_INVESTMENT_ASSET);
      predicates.equalTo('bookId', bookId);
      
      if (keyword && keyword.trim() !== '') {
        predicates.beginWrap();
        predicates.contains('name', keyword);
        predicates.or();
        predicates.contains('code', keyword);
        predicates.endWrap();
      }
      
      // 查询数据
      const resultSet = await this.connection.query(predicates, undefined);
      const assets: InvestmentAssetModel[] = [];
      
      if (!resultSet) {
        return assets;
      }
      
      while (resultSet.goToNextRow()) {
        const asset = this.buildAssetFromResultSet(resultSet);
        assets.push(asset);
      }
      
      resultSet.close();
      
      return assets;
    } catch (error) {
      console.error('搜索投资资产失败', error);
      throw new DatabaseError('搜索投资资产失败', '搜索资产', 9002);
    }
  }

  /**
   * 获取或创建资产
   * @param bookId 账本ID
   * @param code 证券代码
   * @param name 证券名称
   * @param assetType 资产类型
   * @param purchasePrice 购入价格
   * @param currentPrice 当前价格
   * @param quantity 数量
   * @returns 资产对象（已存在的或新创建的）
   */
  async getOrCreateAsset(bookId: number, code: string, name: string, assetType: InvestmentType, 
                          purchasePrice: number, currentPrice: number, quantity: number): Promise<InvestmentAssetModel> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '获取或创建资产', 7001);
      }
      
      // 先尝试查找已存在的资产
      const assetModel = await this.getAssetByCodeAndBookId(bookId, code);
      
      // 如果资产已存在，则返回
      if (assetModel) {
        return assetModel;
      }
      
      // 如果资产不存在，则创建新资产
      const now = new Date().getTime();
      const newAsset = new InvestmentAssetModel(
        bookId,
        code,
        name,
        assetType,
        purchasePrice,
        currentPrice,
        quantity
      );
      
      newAsset.createTime = now;
      newAsset.updateTime = now;
      
      // 保存新资产
      const id = await this.addInvestmentAsset(newAsset);
      newAsset.id = id;
      
      return newAsset;
    } catch (error) {
      console.error('获取或创建资产失败', error);
      throw new DatabaseError('获取或创建资产失败', '获取或创建资产', 7002);
    }
  }
  
  /**
   * 根据证券代码和账本ID获取资产
   * @param bookId 账本ID
   * @param code 证券代码
   * @returns 投资资产对象
   */
  async getAssetByCodeAndBookId(bookId: number, code: string): Promise<InvestmentAssetModel | null> {
    try {
      if (!this.connection) {
        throw new DatabaseError('数据库连接未初始化', '根据代码获取资产', 8001);
      }
      
      // 构建谓词
      const predicates = new dataRdb.RdbPredicates(InvestmentAssetDBHelper.TABLE_INVESTMENT_ASSET);
      predicates.equalTo('bookId', bookId);
      predicates.equalTo('code', code);
      
      // 查询数据
      const resultSet = await this.connection.query(predicates, undefined);
      
      if (!resultSet) {
        return null;
      }
      
      if (resultSet.rowCount <= 0) {
        resultSet.close();
        return null;
      }
      
      if (resultSet.goToFirstRow()) {
        const asset = this.buildAssetFromResultSet(resultSet);
        resultSet.close();
        return asset;
      }
      
      resultSet.close();
      return null;
    } catch (error) {
      console.error('根据代码获取资产失败', error);
      throw new DatabaseError('根据代码获取资产失败', '根据代码获取资产', 8002);
    }
  }
  
  /**
   * 从结果集构建资产对象
   * @param resultSet 结果集
   * @returns 投资资产对象
   */
  private buildAssetFromResultSet(resultSet: dataRdb.ResultSet): InvestmentAssetModel {
    // 直接构造投资资产模型对象
    const id = resultSet.getLong(resultSet.getColumnIndex('id'));
    const bookId = resultSet.getLong(resultSet.getColumnIndex('bookId'));
    const code = resultSet.getString(resultSet.getColumnIndex('code'));
    const name = resultSet.getString(resultSet.getColumnIndex('name'));
    const assetType = resultSet.getLong(resultSet.getColumnIndex('assetType')) as InvestmentType;
    const purchasePrice = resultSet.getDouble(resultSet.getColumnIndex('purchasePrice'));
    const currentPrice = resultSet.getDouble(resultSet.getColumnIndex('currentPrice'));
    const quantity = resultSet.getDouble(resultSet.getColumnIndex('quantity'));
    
    // 构造投资资产对象
    const asset = new InvestmentAssetModel(
      bookId,
      code,
      name,
      assetType,
      purchasePrice,
      currentPrice,
      quantity,
      id
    );
    
    // 设置其他属性
    asset.cost = resultSet.getDouble(resultSet.getColumnIndex('cost'));
    asset.marketValue = resultSet.getDouble(resultSet.getColumnIndex('marketValue'));
    asset.profit = resultSet.getDouble(resultSet.getColumnIndex('profit'));
    asset.profitRate = resultSet.getDouble(resultSet.getColumnIndex('profitRate'));
    asset.updateTime = resultSet.getLong(resultSet.getColumnIndex('updateTime'));
    asset.createTime = resultSet.getLong(resultSet.getColumnIndex('createTime'));
    
    return asset;
  }
}
