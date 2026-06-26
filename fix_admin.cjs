const fs = require('fs');
let p = 'src/views/admin/AdminFloorsView.vue';
let c = fs.readFileSync(p, 'utf8');

c = c.replace(/::placeholder="\$t\('auto_t_auto_nh_p_t_n_kh_ch_d_ng_b_n', '[\s\S]*?'\)"/g, ':placeholder="$t(\'auto_placeholder_fix_1\', \'Nhập tên khách dùng bàn\')"');

c = c.replace(/::placeholder="\$t\('auto_t_auto_nh_p_t_n_kh_ch_h_ng_nha', '[\s\S]*?'\)"/g, ':placeholder="$t(\'auto_placeholder_fix_2\', \'Nhập tên khách hàng\')"');

c = c.replace(/::placeholder="\$t\('auto_t_auto_ghi_ch_th_m_b_n_g_n_c_a', '[\s\S]*?'\)"/g, ':placeholder="$t(\'auto_placeholder_fix_3\', \'Ghi chú thêm: bàn gần cửa sổ...\')"');

c = c.replace(/::placeholder="\$t\('auto_t_auto_v_d_kh_ch_v_ng_lai_anh_', '[\s\S]*?'\)"/g, ':placeholder="$t(\'auto_placeholder_fix_4\', \'Ví dụ: Khách vãng lai / Anh Nam\')"');

fs.writeFileSync(p, c);
console.log('Fixed AdminFloorsView.vue');
