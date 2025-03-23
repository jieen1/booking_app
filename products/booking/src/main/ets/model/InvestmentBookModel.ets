/**
 * 投资账本数据模型
 * 继承自AccountBookModel，增加投资特有属性
 */
import { AccountBookModel } from './AccountBookModel';
import { BookingConstants } from '../constants/BookingConstants';
import { IconUtils } from '../utils/IconUtils';

/**
 * 投资类型枚举
 */
export enum InvestmentType {
  STOCK = 1,        // 股票
  FUND = 2,         // 基金
  BOND = 3,         // 债券
  OTHER = 999       // 其他
}

/**
 * 风险等级枚举
 */
export enum RiskLevel {
  LOW = 1,          // 低风险
  MEDIUM = 2,       // 中等风险
  HIGH = 3          // 高风险
}

/**
 * 投资账本模型
 */
@Observed
export class InvestmentBookModel extends AccountBookModel {
  /**
   * 投资类型：1-股票, 2-基金, 3-债券, 999-其他
   */
  investmentType: InvestmentType;
  
  /**
   * 初始投资金额
   */
  initialInvestment: number;
  
  /**
   * 当前市值
   */
  currentValue: number;
  
  /**
   * 收益率（百分比）
   */
  profitRate: number;
  
  /**
   * 风险等级：1-低风险, 2-中等风险, 3-高风险
   */
  riskLevel: RiskLevel;
  
  constructor(
    name: string, 
    investmentType: InvestmentType = InvestmentType.STOCK,
    balance: number = 0, 
    icon: Resource = IconUtils.getResourceByKey(BookingConstants.ICON_MISC),
    id?: number,
    initialInvestment: number = 0, 
    riskLevel: RiskLevel = RiskLevel.MEDIUM
  ) {
    // 调用父类构造函数 - 使用股票账本类型(5)而不是投资业务类型(1)
    super(name, BookingConstants.ACCOUNT_TYPE_STOCK, balance, icon, 0, id);
    
    this.investmentType = investmentType;
    this.initialInvestment = initialInvestment;
    this.currentValue = initialInvestment; // 初始时市值等于投资金额
    this.profitRate = 0; // 初始收益率为0
    this.riskLevel = riskLevel;
  }
  
  /**
   * 更新当前市值和收益率
   * @param newValue 新的市值
   */
  updateValue(newValue: number): void {
    this.currentValue = newValue;
    // 计算收益率（百分比）
    if (this.initialInvestment > 0) {
      this.profitRate = ((this.currentValue - this.initialInvestment) / this.initialInvestment) * 100;
    } else {
      this.profitRate = 0;
    }
  }
  
  /**
   * 获取盈亏金额
   * @returns 盈亏金额
   */
  getProfitAmount(): number {
    return this.currentValue - this.initialInvestment;
  }
}
