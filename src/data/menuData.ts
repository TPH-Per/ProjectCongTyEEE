// File: src/data/menuData.ts
import type { MenuCategory } from '@/types/customer';

export const menuCategories: MenuCategory[] = [
  // ─── 9 Main Categories màu vàng (Không có subcategories) ──────────────────
  {
    id: 'set-1390',
    name: 'SET 1390',
    color: 'yellow',
    subcategories: [
      {
        id: 'sub-set-1390',
        name: 'Tất cả',
        items: [
          {
            id: 'item-set-1390-1',
            name: 'Set Wagyu Emperor 1390K',
            unit: 'Set',
            price: 1390000,
            price_display: '1.390.000đ',
            category_id: 'set-1390',
            description: 'Set nướng thượng hạng gồm bò Wagyu A5, dẻ sườn rút xương, thăn bò ngoại, nấm đùi gà và panchan ăn kèm.',
            image_url: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'set-1150',
    name: 'SET 1150',
    color: 'yellow',
    subcategories: [
      {
        id: 'sub-set-1150',
        name: 'Tất cả',
        items: [
          {
            id: 'item-set-1150-1',
            name: 'Set Bò Mỹ & Hải Sản 1150K',
            unit: 'Set',
            price: 1150000,
            price_display: '1.150.000đ',
            category_id: 'set-1150',
            description: 'Set nướng kết hợp thăn sườn bò Mỹ chọn lọc và hải sản tươi rói (tôm hùm baby, mực ống).',
            image_url: 'https://images.unsplash.com/photo-1603048588665-791ca8aea617?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'set-680',
    name: 'SET 680',
    color: 'yellow',
    subcategories: [
      {
        id: 'sub-set-680',
        name: 'Tất cả',
        items: [
          {
            id: 'item-set-680-1',
            name: 'Set Gia Đình Ấm Cúng 680K',
            unit: 'Set',
            price: 680000,
            price_display: '680.000đ',
            category_id: 'set-680',
            description: 'Phù hợp cho nhóm 3-4 người gồm thăn vai bò, ba chỉ cuộn nấm, sườn non heo và lẩu nấm nhỏ.',
            image_url: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'set-490',
    name: 'SET 490',
    color: 'yellow',
    subcategories: [
      {
        id: 'sub-set-490',
        name: 'Tất cả',
        items: [
          {
            id: 'item-set-490-1',
            name: 'Set Uyên Ương 490K',
            unit: 'Set',
            price: 490000,
            price_display: '490.000đ',
            category_id: 'set-490',
            description: 'Khẩu phần lãng mạn dành cho 2 người với nạc vai bò Mỹ, ba chỉ heo nướng và salad hoa quả.',
            image_url: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'set-380',
    name: 'SET 380',
    color: 'yellow',
    subcategories: [
      {
        id: 'sub-set-380',
        name: 'Tất cả',
        items: [
          {
            id: 'item-set-380-1',
            name: 'Set Buffet Sinh Viên 380K',
            unit: 'Set',
            price: 380000,
            price_display: '380.000đ',
            category_id: 'set-380',
            description: 'Set buffet tiết kiệm với đầy đủ ba chỉ bò, dọi heo sốt ngọt và rau củ nướng kèm Coca.',
            image_url: 'https://images.unsplash.com/photo-1603048588665-791ca8aea617?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'set-drink',
    name: 'SET DRINK',
    color: 'yellow',
    subcategories: [
      {
        id: 'sub-set-drink',
        name: 'Tất cả',
        items: [
          {
            id: 'item-set-drink-1',
            name: 'Set Beer & Grill Combo',
            unit: 'Combo',
            price: 180000,
            price_display: '180.000đ',
            category_id: 'set-drink',
            description: 'Gồm 4 lon bia Heineken ướp lạnh lạnh và đĩa mực khô nướng thơm bùi.',
            image_url: 'https://images.unsplash.com/photo-1580974852861-e3806103b411?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'ala-carte',
    name: 'A la carte',
    color: 'yellow',
    subcategories: [
      {
        id: 'sub-ala-carte',
        name: 'Tất cả',
        items: [
          {
            id: 'item-ala-carte-1',
            name: 'Dẻ sườn bò Mỹ sốt tiêu',
            unit: 'Đĩa',
            price: 240000,
            price_display: '240.000đ',
            category_id: 'ala-carte',
            description: 'Dẻ sườn bò Mỹ dai giòn tẩm sốt tiêu đen đậm vị nướng lu thơm ngào ngạt.',
            image_url: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=400&q=80',
            is_available: true
          },
          {
            id: 'item-ala-carte-2',
            name: 'Ba chỉ heo sốt muối ớt',
            unit: 'Đĩa',
            price: 110000,
            price_display: '110.000đ',
            category_id: 'ala-carte',
            description: 'Lát ba chỉ heo dày vừa phải ướp muối ớt cay nồng đượm vị nướng.',
            image_url: 'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'set-550jp',
    name: 'Set 550JP',
    color: 'yellow',
    subcategories: [
      {
        id: 'sub-set-550jp',
        name: 'Tất cả',
        items: [
          {
            id: 'item-set-550jp-1',
            name: 'Japanese Bento Premium 550K',
            unit: 'Bento',
            price: 550000,
            price_display: '550.000đ',
            category_id: 'set-550jp',
            description: 'Set Bento chuẩn Nhật bao gồm Sashimi cá hồi, Tempura giòn rụm, cơm lươn Kabayaki và canh Miso nóng hổi.',
            image_url: 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'buffet-lau',
    name: 'Buffet Lẩu',
    color: 'yellow',
    subcategories: [
      {
        id: 'sub-buffet-lau',
        name: 'Tất cả',
        items: [
          {
            id: 'item-buffet-lau-1',
            name: 'Suất Buffet Lẩu Chua Cay',
            unit: 'Người',
            price: 290000,
            price_display: '290.000đ',
            category_id: 'buffet-lau',
            description: 'Ăn thỏa thích hải sản nhúng, thịt bò Mỹ nhúng lẩu Thái cay cay cùng nấm đông cô và rau cải thảo tươi.',
            image_url: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },

  // ─── 9 Main Categories màu hồng (Có subcategories) ────────────────────────
  {
    id: 'cat-buffet',
    name: 'BUFFET',
    color: 'pink',
    subcategories: [
      {
        id: 'sub-buffet-std',
        name: 'Standard',
        items: [
          {
            id: 'item-bf-std-1',
            name: 'Buffet Standard 380k',
            unit: 'Người',
            price: 380000,
            price_display: '380.000đ',
            category_id: 'cat-buffet',
            description: 'Buffet chuẩn mực với sườn heo, gầu bò Mỹ, đùi gà rút xương sốt BBQ.',
            image_url: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      },
      {
        id: 'sub-buffet-prem',
        name: 'Premium',
        items: [
          {
            id: 'item-bf-prem-1',
            name: 'Buffet Premium 680k',
            unit: 'Người',
            price: 680000,
            price_display: '680.000đ',
            category_id: 'cat-buffet',
            description: 'Bao gồm nướng lẩu thả ga, dẻ sườn Wagyu, hải sản phong phú và tráng miệng kem Ý.',
            image_url: 'https://images.unsplash.com/photo-1603048588665-791ca8aea617?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'cat-lunch',
    name: 'Set Lunch',
    color: 'pink',
    subcategories: [
      {
        id: 'sub-lunch-office',
        name: 'Cơm Trưa Văn Phòng',
        items: [
          {
            id: 'item-lunch-1',
            name: 'Cơm bò xào sốt tiêu đen',
            unit: 'Suất',
            price: 85000,
            price_display: '85.000đ',
            category_id: 'cat-lunch',
            description: 'Cơm trắng dẻo ăn kèm thịt bò xào tiêu đen nồng đượm vị thơm cùng canh rau.',
            image_url: 'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      },
      {
        id: 'sub-lunch-ramen',
        name: 'Mì & Soup trưa',
        items: [
          {
            id: 'item-lunch-2',
            name: 'Mì Ramen xá xíu trứng lòng đào',
            unit: 'Tô',
            price: 95000,
            price_display: '95.000đ',
            category_id: 'cat-lunch',
            description: 'Tô mì nước cốt xương hầm 12 tiếng béo ngậy cùng thịt xá xíu mềm.',
            image_url: 'https://images.unsplash.com/photo-1555126634-323283e090fa?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'cat-tiec',
    name: 'SET TIỆC CHIÊU ĐÃI',
    color: 'pink',
    subcategories: [
      {
        id: 'sub-tiec-corp',
        name: 'Tiệc Công Ty',
        items: [
          {
            id: 'item-tiec-corp-1',
            name: 'Bàn Tiệc Đại Hỷ (10 người)',
            unit: 'Bàn',
            price: 4500000,
            price_display: '4.500.000đ',
            category_id: 'cat-tiec',
            description: 'Combo tiệc công ty hoành tráng gồm 6 món chính: sườn bò, salad sứa, lẩu tôm càng và hoa quả.',
            image_url: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'cat-tiec-jp',
    name: 'SET TIỆC CHIÊU ĐÃI (JP)',
    color: 'pink',
    subcategories: [
      {
        id: 'sub-tiec-jp-1',
        name: 'Sushi & Sashimi Feast',
        items: [
          {
            id: 'item-tiec-jp-1',
            name: 'Thuyền Sashimi Cực Phẩm',
            unit: 'Thuyền',
            price: 1200000,
            price_display: '1.200.000đ',
            category_id: 'cat-tiec-jp',
            description: 'Cá hồi Nhật, cá trích ép trứng, bạch tuộc đỏ, sò đỏ thái mỏng xếp trên thuyền gỗ.',
            image_url: 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'cat-vietravel',
    name: 'SET Vietravel',
    color: 'pink',
    subcategories: [
      {
        id: 'sub-vietravel-1',
        name: 'Đoàn Khách Lữ Hành',
        items: [
          {
            id: 'item-vt-1',
            name: 'Set Cơm Đoàn 150K',
            unit: 'Suất',
            price: 150000,
            price_display: '150.000đ',
            category_id: 'cat-vietravel',
            description: 'Bữa cơm trưa đầy đặn tiện lợi gồm sườn rim chua ngọt, canh cua cà pháo và cá kho tộ.',
            image_url: 'https://images.unsplash.com/photo-1555126634-323283e090fa?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'cat-thucan',
    name: 'Thức Ăn',
    color: 'pink',
    subcategories: [
      {
        id: 'sub-ta-bo',
        name: 'Thịt Bò',
        items: [
          {
            id: 'm1000000-0000-0000-0000-000000000001',
            name: 'Bò Wagyu A5',
            unit: 'Đĩa',
            price: 500000,
            price_display: '500.000đ',
            category_id: 'cat-thucan',
            description: 'Bò Wagyu vân mỡ tuyệt vời nướng chín mềm ngọt nước tan chảy trong miệng.',
            image_url: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=400&q=80',
            is_available: true
          },
          {
            id: 'm1000000-0000-0000-0000-000000000002',
            name: 'Thăn ngoại bò Mỹ',
            unit: 'Đĩa',
            price: 200000,
            price_display: '200.000đ',
            category_id: 'cat-thucan',
            description: 'Thăn bò Mỹ mềm ngậy thơm ngập tràn tẩm ướp tiêu đen.',
            image_url: 'https://images.unsplash.com/photo-1603048588665-791ca8aea617?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      },
      {
        id: 'sub-ta-heo',
        name: 'Thịt Heo & Gà',
        items: [
          {
            id: 'item-ba-chi',
            name: 'Ba chỉ cuộn nấm kim châm',
            unit: 'Đĩa',
            price: 120000,
            price_display: '120.000đ',
            category_id: 'cat-thucan',
            description: 'Thịt heo cuộn kim châm ngọt giòn nướng cuốn rau xà lách.',
            image_url: 'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      },
      {
        id: 'sub-ta-side',
        name: 'Món Ăn Kèm',
        items: [
          {
            id: 'm1000000-0000-0000-0000-000000000003',
            name: 'Salad rau củ',
            unit: 'Đĩa',
            price: 50000,
            price_display: '50.000đ',
            category_id: 'cat-thucan',
            description: 'Salad rau tươi trộn nước sốt mè bùi bùi giải ngấy thịt nướng.',
            image_url: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'cat-thuocuong',
    name: 'Thức Uống',
    color: 'pink',
    subcategories: [
      {
        id: 'sub-tu-soft',
        name: 'Nước ngọt',
        items: [
          {
            id: 'm1000000-0000-0000-0000-000000000004',
            name: 'Coca Cola',
            unit: 'Lon',
            price: 30000,
            price_display: '30.000đ',
            category_id: 'cat-thuocuong',
            description: 'Nước ngọt giải khát đầy ga sảng khoái mát lạnh.',
            image_url: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'cat-con',
    name: 'Thức Uống Có Cồn',
    color: 'pink',
    subcategories: [
      {
        id: 'sub-tu-soju',
        name: 'Rượu Soju',
        items: [
          {
            id: 'm1000000-0000-0000-0000-000000000005',
            name: 'Rượu Soju',
            unit: 'Chai',
            price: 100000,
            price_display: '100.000đ',
            category_id: 'cat-con',
            description: 'Vị êm mượt đặc trưng nhâm nhi cùng thịt nướng nóng hổi xèo xèo.',
            image_url: 'https://images.unsplash.com/photo-1580974852861-e3806103b411?auto=format&fit=crop&w=400&q=80',
            is_available: true
          }
        ]
      }
    ]
  },
  {
    id: 'cat-other',
    name: 'Khác',
    color: 'pink',
    subcategories: [
      {
        id: 'sub-other-tissue',
        name: 'Vật dụng sạch',
        items: [
          {
            id: 'item-other-tissue-1',
            name: 'Khăn ướt lạnh',
            unit: 'Cái',
            price: 5000,
            price_display: '5.000đ',
            category_id: 'cat-other',
            description: 'Khăn lạnh sạch sẽ lau tay giữ vệ sinh ăn uống.',
            image_url: '',
            is_available: true
          }
        ]
      }
    ]
  }
];
