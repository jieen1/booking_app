/**
 * Copyright (c) 2023 Harmony OS App Project
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
