/**
 * 老人档案模型
 */
@Observed
export class Elder {
  id: string = '';
  name: string = '';
  age: number = 0;
  gender: 'male' | 'female' = 'male';
  avatar: string = '';
  address: string = '';
  phone: string = '';
  medicalHistory: string = '';
  emergencyContacts: EmergencyContact[] = [];
  communityGrid: string = '';   // 社区网格员
  communityPhone: string = '';
}

@Observed
export class EmergencyContact {
  id: string = '';
  name: string = '';
  relation: string = '';        // 儿子 / 女儿 / 邻居 / 社区
  phone: string = '';
  priority: number = 1;         // 呼叫顺序
  notifyEnabled: boolean = true;
}
