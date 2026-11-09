-- ============================================================================
-- STRUKKU - Data awal tabel categories (5 kategori standar)
-- Jalankan SETELAH schema_postgresql.sql.
-- ID sengaja eksplisit (1..5) agar sama dengan database lokal SQLite aplikasi.
-- ============================================================================

INSERT INTO categories (id, name, description) VALUES
    (1, 'F&B',          'Makanan, minuman, dan bahan pangan'),
    (2, 'Kesehatan',    'Obat, vitamin, dan kebutuhan medis'),
    (3, 'Transportasi', 'Ojek, taksi, BBM, dan angkutan umum'),
    (4, 'Belanja',      'Pakaian dan kebutuhan rumah tangga'),
    (5, 'Lainnya',      'Pengeluaran di luar kategori utama')
ON CONFLICT (name) DO NOTHING;

-- Sinkronkan sequence identity setelah insert dengan ID eksplisit.
SELECT setval(pg_get_serial_sequence('categories', 'id'),
              (SELECT MAX(id) FROM categories));
