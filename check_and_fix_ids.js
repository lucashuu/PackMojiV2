const fs = require('fs');

// 读取items.json
const items = JSON.parse(fs.readFileSync('backend/items.json', 'utf8'));

// 获取所有实际存在的ID
const existingIds = items.map(item => item.id);

// 定义脚本中使用的ID列表
const scriptIds = {
  essentials: [
    'passport', 'visa_info', 'international_driving_permit_info', 'id_card_cn', 
    'id_card_us', 'credit_card', 'drivers_license', 'student_id', 'cash', 
    'keys', 'tickets', 'insurance_info', 'emergency_contacts', 'hotel_reservation', 
    'flight_reservation'
  ],
  electronics: [
    'phone', 'tablet', 'laptop', 'camera', 'smartwatch', 'headphones', 
    'power_bank', 'phone_charger', 'laptop_charger', 'camera_charger', 
    'tablet_charger', 'smartwatch_charger', 'adapter', 'gps_device', 'portable_wifi'
  ],
  clothing: [
    't_shirt', 'long_sleeve_shirt', 'blouse', 'sweater', 'tank_top', 'base_layer',
    'sun_protection_shirt', 'thermal_underwear', 'pajamas', 'swimsuit', 'fancy_dress',
    'business_suit', 'rain_poncho', 'light_jacket', 'heavy_jacket', 'hardshell_jacket',
    'down_jacket', 'sports_jacket', 'wool_coat', 'ski_jacket', 'jeans', 'shorts',
    'skirt', 'leggings', 'casual_pants', 'sports_pants', 'dress_pants', 'quick_dry_pants',
    'sneakers', 'sandals', 'boots', 'hiking_boots', 'ski_boots', 'dress_shoes',
    'casual_shoes', 'flip_flops', 'formal_shoes', 'socks', 'underwear', 'sport_bra',
    'bra', 'thermal_socks', 'hiking_socks', 'scarf', 'gloves', 'belt', 'sunglasses',
    'jewelry', 'tie', 'hat', 'cap', 'winter_hat', 'bandana', 'watch', 'hat_cap',
    'hiking_gloves', 'neck_warmer', 'evening_bag', 'hiking_backpack', 'hair_styling_tools'
  ],
  personal_care: [
    'toothbrush_paste', 'face_wash', 'shampoo', 'conditioner', 'body_wash', 'deodorant',
    'razor', 'shaving_cream', 'hair_brush', 'hair_dryer', 'curling_iron', 'nail_clippers',
    'tweezers', 'cotton_swabs', 'cotton_pads', 'makeup_remover', 'facial_cleanser',
    'toner', 'moisturizer', 'sunscreen', 'lip_balm', 'hand_cream', 'body_lotion',
    'perfume', 'cologne', 'sanitary_pads', 'tampons', 'condoms', 'lubricant'
  ],
  cosmetics: [
    'foundation', 'concealer', 'powder', 'blush', 'bronzer', 'eyeshadow', 'eyeliner',
    'mascara', 'eyebrow_pencil', 'lipstick', 'lip_gloss', 'makeup_brushes',
    'makeup_sponge', 'makeup_remover_wipes', 'nail_polish', 'nail_polish_remover'
  ],
  medical: [
    'band_aids', 'medical_tape', 'alcohol_wipes', 'antiseptic', 'first_aid_kit',
    'thermometer', 'pain_relievers', 'painkillers', 'fever_reducers', 'antihistamines',
    'antacids', 'motion_sickness_pills', 'diarrhea_medicine', 'constipation_medicine',
    'cough_syrup', 'cold_medicine', 'vitamins', 'prescription_medications',
    'personal_medications', 'insect_repellent', 'mosquito_repellent', 'sunscreen_medical'
  ],
  beach: [
    'beach_towel', 'beach_umbrella', 'beach_chair', 'beach_blanket', 'beach_bag',
    'beach_ball', 'snorkel_mask', 'water_shoes', 'beach_cover_up', 'beach_hat'
  ],
  skiing: [
    'ski_jacket', 'ski_pants', 'ski_boots', 'ski_helmet', 'ski_goggles', 'ski_gloves',
    'ski_socks', 'ski_poles', 'ski_equipment', 'hand_warmers'
  ],
  camping: [
    'tent', 'sleeping_bag', 'sleeping_pad', 'camping_stove', 'camping_chair',
    'camping_table', 'camping_lantern', 'camping_gear', 'hiking_boots', 'hiking_poles',
    'backpack', 'water_bottle', 'compass', 'map'
  ],
  business: [
    'laptop', 'laptop_charger', 'business_cards', 'notebook', 'pen', 'folder',
    'presentation_remote', 'business_attire', 'dress_shoes', 'tie', 'belt'
  ],
  comfort: [
    'travel_pillow', 'eye_mask', 'earplugs', 'travel_blanket', 'slippers', 'robe',
    'hotel_slippers', 'massage_device', 'heating_pad', 'cooling_pad'
  ],
  food: [
    'snacks', 'energy_bars', 'nuts', 'chocolate', 'candy', 'gum', 'tea', 'coffee',
    'water', 'juice'
  ],
  miscellaneous: [
    'towel', 'umbrella', 'raincoat', 'plastic_bags', 'ziploc_bags', 'duct_tape',
    'scissors', 'safety_pins', 'rubber_bands', 'paper_clips', 'sticky_notes',
    'markers', 'books', 'magazines', 'games', 'cards', 'puzzles', 'toys', 'gifts', 'souvenirs'
  ]
};

// 检查缺失的ID
const missingIds = [];
const allScriptIds = [];

Object.values(scriptIds).forEach(group => {
  group.forEach(id => {
    allScriptIds.push(id);
    if (!existingIds.includes(id)) {
      missingIds.push(id);
    }
  });
});

console.log('🔍 ID检查结果：');
console.log('📊 总计检查ID数量：', allScriptIds.length);
console.log('❌ 缺失的ID数量：', missingIds.length);

if (missingIds.length > 0) {
  console.log('\n❌ 缺失的ID：');
  missingIds.forEach(id => console.log(`  - ${id}`));
  
  // 查找可能的替代ID
  console.log('\n🔍 查找可能的替代ID：');
  missingIds.forEach(missingId => {
    const similarIds = existingIds.filter(existingId => 
      existingId.includes(missingId.split('_')[0]) || 
      existingId.includes(missingId.split('_')[1])
    );
    if (similarIds.length > 0) {
      console.log(`  ${missingId} -> 可能的替代: ${similarIds.join(', ')}`);
    }
  });
} else {
  console.log('✅ 所有ID都存在！');
}

// 检查一些特定的ID映射
console.log('\n🔍 特定ID检查：');
const specificChecks = [
  { script: 'tablet', actual: 'ipad' },
  { script: 'tablet_charger', actual: 'ipad_charger' },
  { script: 'bra', actual: 'sport_bra' },
  { script: 'tickets', actual: 'flight_reservation' },
  { script: 'insurance_info', actual: null },
  { script: 'adapter', actual: null },
  { script: 'gps_device', actual: null },
  { script: 'portable_wifi', actual: null }
];

specificChecks.forEach(check => {
  if (check.actual && existingIds.includes(check.actual)) {
    console.log(`✅ ${check.script} -> ${check.actual} (存在)`);
  } else if (check.actual) {
    console.log(`❌ ${check.script} -> ${check.actual} (不存在)`);
  } else {
    console.log(`❌ ${check.script} (不存在)`);
  }
}); 