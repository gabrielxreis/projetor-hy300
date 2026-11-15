package com.cinemaemcasa.configuracoes;

import android.accessibilityservice.AccessibilityService;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;
import java.util.List;

/**
 * Quando o sistema do projetor mostra "Pressione o botao de energia novamente ou OK
 * para desligar a energia", confirma o OK sozinho. Assim um toque no botao de energia
 * do controle ja desliga. So age nessa tela (pacote "android", texto com "desligar").
 */
public class DesligarDireto extends AccessibilityService {
    private long ultimo = 0;

    @Override
    public void onAccessibilityEvent(AccessibilityEvent e) {
        if (e == null || e.getPackageName() == null || !"android".contentEquals(e.getPackageName())) return;
        AccessibilityNodeInfo raiz = getRootInActiveWindow();
        if (raiz == null) return;
        try {
            List<AccessibilityNodeInfo> msgs = raiz.findAccessibilityNodeInfosByViewId("android:id/message");
            boolean ehDesligar = false;
            for (AccessibilityNodeInfo m : msgs) {
                CharSequence t = m.getText();
                if (t != null) {
                    String s = t.toString().toLowerCase();
                    if (s.contains("desligar") || s.contains("power off") || s.contains("shut")) ehDesligar = true;
                }
            }
            if (!ehDesligar) return;
            long agora = System.currentTimeMillis();
            if (agora - ultimo < 2000) return;   // um clique so
            for (AccessibilityNodeInfo b : raiz.findAccessibilityNodeInfosByViewId("android:id/button1")) {
                if (b.isEnabled() && b.performAction(AccessibilityNodeInfo.ACTION_CLICK)) { ultimo = agora; return; }
            }
        } catch (Exception ignored) {
        }
    }

    @Override
    public void onInterrupt() { }
}
