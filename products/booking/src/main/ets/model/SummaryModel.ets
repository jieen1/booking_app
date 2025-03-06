/**
 * 收支汇总数据接口
 */
export interface SummaryData {
  /**
   * 收入
   */
  income: number;
  
  /**
   * 支出
   */
  expense: number;
}

/**
 * 分类汇总数据接口
 */
export interface CategorySummary {
  /**
   * 分类ID
   */
  categoryId: number;
  
  /**
   * 分类名称
   */
  categoryName: string;
  
  /**
   * 分类图标
   */
  icon: string;
  
  /**
   * 金额
   */
  amount: number;
}