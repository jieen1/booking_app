/**
 * 记账记录数据模型
 */
export class RecordModel {
  /**
   * 记录ID
   */
  id?: number;

  /**
   * 记录类型: 1-收入, 2-支出
   */
  type: number;

  /**
   * 类别ID
   */
  categoryId: number;

  /**
   * 金额
   */
  amount: number;

  /**
   * 记录描述
   */
  description: string;

  /**
   * 记录时间
   */
  recordTime: number;

  /**
   * 创建时间
   */
  createTime: number;
  
  /**
   * 所属账本ID
   */
  accountBookId: number = 1; // 默认为1，表示默认账本
  
  constructor(type: number, categoryId: number, amount: number, 
              description: string, recordTime: number, accountBookId: number = 1, 
              createTime: number = new Date().getTime(), id?: number) {
    this.id = id;
    this.type = type;
    this.categoryId = categoryId;
    this.amount = amount;
    this.description = description;
    this.recordTime = recordTime;
    this.accountBookId = accountBookId;
    this.createTime = createTime;
  }
}
