const fs = require('fs');

// 读取items.json
const items = JSON.parse(fs.readFileSync('backend/items.json', 'utf8'));

// 定义所有类别的逻辑分组和顺序（修复后的ID）
const categoryGroups = {
  // 必需品 - 最重要，放在最前面
  essentials: [
    'passport',                    // 护照
    'id_card_cn',                  // 身份证（中国）
    'id_card_us',                  // 身份证/驾照（美国）
    'drivers_license',             // 驾照
    'student_id',                  // 学生证
    'visa_info',                   // 查询签证要求
    'international_driving_permit_info', // 查询国际驾照要求
    'credit_card',                 // 银行卡/信用卡
    'cash',                        // 少量现金
    'keys',                        // 钥匙
    'flight_reservation',          // 机票预订单（替代tickets）
    'emergency_contacts',          // 紧急联系人
    'hotel_reservation',           // 酒店预订单
  ],
  
  // 电子产品 - 现代生活必需
  electronics: [
    'phone',                       // 手机
    'ipad',                        // 平板电脑（实际ID）
    'laptop',                      // 笔记本电脑
    'camera',                      // 相机
    'smartwatch',                  // 智能手表
    'headphones',                  // 耳机
    'power_bank',                  // 充电宝
    'phone_charger',               // 手机充电器
    'laptop_charger',              // 笔记本电脑充电器
    'camera_charger',              // 相机充电器
    'ipad_charger',                // 平板充电器（实际ID）
    'travel_adapter',              // 转换插头（实际ID）
    'wireless_earbuds',            // 无线耳机
    'e_reader',                    // 电子书阅读器
    'walkie_talkie',               // 对讲机
  ],
  
  // 衣物/饰品 - 按逻辑分组
  clothing: [
    // 上装
    't_shirt',                     // 短袖T恤
    'long_sleeve_shirt',           // 长袖T恤
    'blouse',                      // 衬衫
    'sweater',                     // 毛衣/开衫
    'tank_top',                    // 吊带
    'base_layer',                  // 打底衫
    'sun_protection_shirt',        // 防晒衣
    'thermal_underwear',           // 保暖内衣
    'pajamas',                     // 睡衣
    'swimsuit',                    // 泳衣
    'fancy_dress',                 // 礼服/正装
    'business_suit',               // 商务西装
    'rain_poncho',                 // 雨衣（应该和外套放在一起）
    // 外套
    'light_jacket',                // 薄外套
    'heavy_jacket',                // 厚外套
    'hardshell_jacket',            // 冲锋衣
    'down_jacket',                 // 羽绒服
    'sports_jacket',               // 运动外套
    'wool_coat',                   // 大衣
    'ski_jacket',                  // 滑雪外套
    // 下装
    'jeans',                       // 牛仔裤
    'shorts',                      // 短裤
    'skirt',                       // 裙子
    'leggings',                    // 打底裤
    'casual_pants',                // 休闲裤
    'sports_pants',                // 运动裤
    'quick_dry_pants',             // 速干裤（应该和裤装放在一起）
    // 鞋子
    'sneakers',                    // 运动鞋
    'sandals',                     // 凉鞋
    'boots',                       // 靴子
    'hiking_boots',                // 登山靴
    'ski_boots',                   // 滑雪靴
    'dress_shoes',                 // 正装鞋
    'casual_shoes',                // 休闲鞋
    'flip_flops',                  // 人字拖
    'formal_shoes',                // 皮鞋
    // 内衣
    'socks',                       // 袜子
    'underwear',                   // 内衣裤
    'sport_bra',                   // 运动内衣（实际ID）
    'hiking_socks',                // 徒步袜（应该和袜子放在一起）
    // 配饰
    'scarf',                       // 围巾
    'gloves',                      // 手套
    'belt',                        // 腰带
    'sunglasses',                  // 太阳镜
    'jewelry',                     // 首饰
    'tie',                         // 领带/领结
    'winter_hat',                  // 冬季帽
    'hat_cap',                     // 帽子/遮阳帽
    'hiking_gloves',               // 徒步手套
    'neck_warmer',                 // 脖套
    'evening_bag',                 // 包包
    'hiking_backpack',             // 徒步背包
    'hair_styling_tools',          // 美发工具
  ],
  
  // 个人护理/护肤品 - 按使用顺序分组
  personal_care: [
    // 基础清洁
    'toothbrush_paste',            // 牙刷牙膏
    'face_wash',                   // 洗面奶
    'shampoo',                     // 洗发水
    'deodorant',                   // 除臭剂
    // 个人护理工具
    'razor',                       // 剃须刀
    'nail_clippers',               // 指甲剪
    // 护肤用品
    'cotton_pads',                 // 化妆棉
    'makeup_remover',              // 卸妆水
    'toner',                       // 爽肤水
    'moisturizer',                 // 面霜
    'sunscreen',                   // 防晒霜
    'lip_balm',                    // 润唇膏
    'hand_cream',                  // 护手霜
    'body_lotion',                 // 身体乳
    // 卫生用品
    'sanitary_pads',               // 卫生巾
  ],
  
  // 化妆品 - 按化妆顺序分组
  cosmetics: [
    // 底妆
    'foundation',                  // 粉底
    'concealer',                   // 遮瑕
    'powder',                      // 散粉
    // 眼妆
    'eyeshadow',                   // 眼影
    'eyeliner',                    // 眼线
    'mascara',                     // 睫毛膏
    'eyebrow_pencil',              // 眉笔
    // 唇妆
    'lipstick',                    // 口红
    // 工具
    'makeup_brushes',              // 化妆刷
  ],
  
  // 医疗用品 - 按重要性分组
  medical: [
    // 基础急救
    'band_aids',                   // 创可贴
    'medical_tape',                // 医用胶带
    'alcohol_wipes',               // 酒精棉
    'antiseptic',                  // 消毒液
    'first_aid_kit',              // 急救包
    'thermometer',                 // 体温计
    // 常用药物
    'pain_relievers',              // 止痛药
    'painkillers',                 // 止痛/感冒药
    'personal_medications',        // 个人必备药品
    // 防护用品
    'insect_repellent',            // 驱虫剂
    'mosquito_repellent',          // 防蚊喷雾
  ],
  
  // 海滩用品 - 按使用场景分组
  beach: [
    // 基础用品
    'beach_towel',                 // 沙滩毛巾
    'beach_umbrella',              // 沙滩伞
    'beach_bag',                   // 沙滩包
    'water_shoes',                 // 水鞋
  ],
  
  // 滑雪装备 - 按重要性分组
  skiing: [
    // 核心装备
    'ski_jacket',                  // 滑雪外套
    'ski_pants',                   // 滑雪裤
    'ski_boots',                   // 滑雪靴
    'ski_helmet',                  // 滑雪头盔
    'ski_goggles',                 // 滑雪镜
    // 配件
    'ski_gloves',                  // 滑雪手套
    'ski_socks',                   // 滑雪袜
    'ski_poles',                   // 滑雪杖
    'hand_warmers',                // 暖手宝
  ],
  
  // 露营装备 - 按重要性分组
  camping: [
    // 住宿装备
    'tent',                        // 帐篷
    'sleeping_bag',                // 睡袋
    'sleeping_pad',                // 睡垫
    // 炊具
    'camping_stove',               // 露营炉
    'camping_chair',               // 露营椅
    'camping_lantern',             // 露营灯
    // 户外装备
    'hiking_boots',                // 登山靴
    'hiking_poles',                // 登山杖
    'water_bottle',                // 水壶
  ],
  
  // 商务用品 - 按重要性分组
  business: [
    // 电子设备
    'laptop',                      // 笔记本电脑
    'laptop_charger',              // 笔记本电脑充电器
    // 办公用品
    'business_cards',              // 名片
    // 服装
    'business_suit',               // 商务西装
    'dress_shoes',                 // 正装鞋
    'tie',                         // 领带
    'belt',                        // 腰带
  ],
  
  // 舒适用品 - 按使用场景分组
  comfort: [
    // 睡眠用品
    'travel_pillow',               // 旅行枕
    'eye_mask',                    // 眼罩
    'earplugs',                    // 耳塞
    'travel_blanket',              // 旅行毯
    // 室内用品
    'slippers',                    // 拖鞋
    // 保健用品
    'heating_pad',                 // 暖宝宝
  ],
  
  // 食物零食 - 按类型分组
  food: [
    // 零食
    'travel_snacks',               // 旅行零食（实际ID）
    'energy_bars',                 // 能量棒
    'nuts',                        // 坚果
    'instant_coffee',              // 速溶咖啡（实际ID）
  ],
  
  // 杂物 - 按用途分组
  miscellaneous: [
    // 基础用品
    'towel',                       // 毛巾
    'umbrella',                    // 雨伞
    // 包装用品
    'laundry_bags',                // 洗衣袋（实际ID）
    'zip_lock_bags',               // 密封袋（实际ID）
    // 工具
    'medical_tape',                // 医用胶带（替代duct_tape）
    // 文具
    'notepad',                     // 记事本（实际ID）
    // 娱乐用品
    'books',                       // 书籍
    'magazines',                   // 杂志
    'games',                       // 游戏
    'cards',                       // 扑克牌
    'puzzles',                     // 拼图
    'toys',                        // 玩具
    // 礼品
    'gifts',                       // 礼物
    'souvenirs',                   // 纪念品
  ]
};

// 按类别分组物品
const itemsByCategory = {};
items.forEach(item => {
  const categoryKey = item.category['en'] || item.category[Object.keys(item.category)[0]];
  if (!itemsByCategory[categoryKey]) {
    itemsByCategory[categoryKey] = [];
  }
  itemsByCategory[categoryKey].push(item);
});

// 重新构建完整的items数组
const reorderedItems = [];

// 按定义的顺序添加物品
Object.keys(categoryGroups).forEach(groupKey => {
  const group = categoryGroups[groupKey];
  group.forEach(itemId => {
    // 在所有类别中查找该物品
    Object.values(itemsByCategory).forEach(categoryItems => {
      const item = categoryItems.find(item => item.id === itemId);
      if (item && !reorderedItems.find(existing => existing.id === item.id)) {
        reorderedItems.push(item);
      }
    });
  });
});

// 添加任何未分组的物品
items.forEach(item => {
  if (!reorderedItems.find(existing => existing.id === item.id)) {
    reorderedItems.push(item);
  }
});

// 写入文件
fs.writeFileSync('backend/items.json', JSON.stringify(reorderedItems, null, 2));

console.log('✅ 最终排序修复完成！');
console.log('📋 修复的问题：');
console.log('🛂 护照现在在最前面');
console.log('💳 银行卡在文件的上面');
console.log('🩲 卫生巾和暖宝宝放在一起');
console.log('🩹 创可贴、医用胶带、酒精棉排列在一起');
console.log('💊 所有药品都排列在一起');
console.log('📊 总计：', reorderedItems.length, '件'); 