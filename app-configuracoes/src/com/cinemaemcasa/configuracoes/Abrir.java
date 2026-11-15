package com.cinemaemcasa.configuracoes;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

/** Abre o app de configurações do projetor e some. */
public class Abrir extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Intent i = getPackageManager().getLaunchIntentForPackage("com.android.tv.settings");
        if (i == null) {
            i = new Intent(android.provider.Settings.ACTION_SETTINGS);
        }
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        try {
            startActivity(i);
        } catch (Exception e) {
            startActivity(new Intent(android.provider.Settings.ACTION_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        }
        finish();
    }
}
