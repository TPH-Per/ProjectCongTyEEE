const fs = require('fs');
['vi', 'en', 'ja'].forEach(lang => {
  let p = `src/locales/${lang}.ts`;
  let c = fs.readFileSync(p, 'utf8');
  
  // Specifically fix the multiline translation entry issue
  // The entry is likely:
  // auto_t_auto_v_d_kh_ch_v_ng_lai_anh_na: '                t(
  //                   \'auto_v_d_kh_ch_v_ng_lai_anh_na\',
  //                   \'Ví dụ: Khách vãng lai / Anh Nam\',
  //                 )
  //               ',
  
  // To fix it generically, we can match keys that have newlines before the next key
  // But a safer way is to just replace \n inside values with space or \n literal.
  // Actually, wait, it's a literal \n inside a string delimited by single quotes.
  // Let's just fix the bad entry directly.
  c = c.replace(/auto_t_auto_v_d_kh_ch_v_ng_lai_anh_na:\s*'[^']*',/gs, "auto_t_auto_v_d_kh_ch_v_ng_lai_anh_na: 'Ví dụ: Khách vãng lai / Anh Nam',");
  
  // also auto_th_m_t_nh_n_kh_ch_h_ng_kh_ng_b : '...
  // there might be others.
  
  // Let's do a more robust fix: convert all values to use backticks, or replace literal newlines.
  // We can match every key-value pair and sanitize the value.
  const regex = /^(\s*(?:'[^']+'|[a-zA-Z0-9_]+)\s*:\s*)'([\s\S]*?)'(,$)/gm;
  c = c.replace(regex, (match, prefix, value, suffix) => {
    // If value contains a literal newline, escape it
    if (value.includes('\n')) {
      const sanitized = value.replace(/\n/g, '\\n').replace(/\r/g, '');
      return prefix + "'" + sanitized + "'" + suffix;
    }
    return match;
  });

  fs.writeFileSync(p, c);
});
