/**
 * u8f6cu8d26u8bb0u5f55u6570u636eu6a21u578b
 */
export class TransferModel {
  /**
   * u8f6cu8d26u8bb0u5f55ID
   */
  id?: number;
  
  /**
   * u6765u6e90u8d26u672cID
   */
  fromAccountId: number;
  
  /**
   * u76eeu6807u8d26u672cID
   */
  toAccountId: number;
  
  /**
   * u8f6cu8d26u91d1u989d
   */
  amount: number;
  
  /**
   * u63cfu8ff0
   */
  description: string;
  
  /**
   * u5173u8054u8bb0u5f55IDuff08u5339u914du7684u53e6u4e00u6761u8f6cu8d26u8bb0u5f55uff09
   */
  relatedId?: number;
  
  /**
   * u8f6cu8d26u65f6u95f4
   */
  transferTime: number;
  
  /**
   * u521bu5efau65f6u95f4
   */
  createTime: number;
  
  constructor(
    fromAccountId: number, 
    toAccountId: number, 
    amount: number, 
    description: string = '', 
    transferTime: number = new Date().getTime(),
    relatedId?: number,
    id?: number
  ) {
    this.id = id;
    this.fromAccountId = fromAccountId;
    this.toAccountId = toAccountId;
    this.amount = amount;
    this.description = description;
    this.relatedId = relatedId;
    this.transferTime = transferTime;
    this.createTime = new Date().getTime();
  }
}
