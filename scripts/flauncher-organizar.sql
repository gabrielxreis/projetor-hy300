-- Organiza o FLauncher (rodar NO PROJETOR como root, com o FLauncher parado):
--   adb shell 'am force-stop me.efesser.flauncher; cd /data/data/me.efesser.flauncher/app_flutter; cp db.sqlite /data/local/tmp/db-backup.sqlite'
--   adb push flauncher-organizar.sql /data/local/tmp/ && adb shell 'cd /data/data/me.efesser.flauncher/app_flutter; sqlite3 db.sqlite < /data/local/tmp/flauncher-organizar.sql; input keyevent KEYCODE_HOME'
-- Tabelas: apps (hidden), categories, apps_categories (ordem), launcher_spacers (espaco que empurra a fileira).

-- esconde o que a crianca nao precisa ver
UPDATE apps SET hidden=1 WHERE package_name IN ('com.android.tv.settings','com.android.vending');

-- uma categoria so; o nome com quebras de linha empurra a fileira para baixo do desenho do fundo
DELETE FROM categories WHERE id<>1;
UPDATE categories SET name=char(10,10,10,10,10,10,10,10,10,10,10,10,32) WHERE id=1;

-- ordem dos apps na fileira
INSERT OR REPLACE INTO apps_categories VALUES (1,'com.google.android.youtube.tv',0);
INSERT OR REPLACE INTO apps_categories VALUES (1,'com.netflix.mediaclient',1);
INSERT OR REPLACE INTO apps_categories VALUES (1,'com.cinemaemcasa.configuracoes',99);
