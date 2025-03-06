/**
 * 账本数据模型
 */
export class AccountBookModel {
  /**
   * 账本ID
   */
  id?: number;
  
  /**
   * 账本名称
   */
  name: string;
  
  /**
   * 账本类型：1-现金账本, 2-银行卡, 3-支付宝, 4-微信, 5-股票  999-其他
   */
  type: number;
  
  /**
   * 账本余额
   */
  balance: number;
  
  /**
   * 是否为默认账本：0-否, 1-是
   */
  isDefault: number;
  
  /**
   * 账本图标
   */
  icon: Resource;
  
  /**
   * 创建时间
   */
  createTime: number;
  
  constructor(name: string, type: number, balance: number = 0, icon: Resource, isDefault: number = 0, id?: number) {
    this.id = id;
    this.name = name;
    this.type = type;
    this.balance = balance;
    this.isDefault = isDefault;
    this.icon = icon;
    this.createTime = new Date().getTime();
  }
}
