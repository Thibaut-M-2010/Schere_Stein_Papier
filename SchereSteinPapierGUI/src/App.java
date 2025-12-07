import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionListener;
import java.awt.image.BufferedImage;
import java.io.File;

public class App {
    // cleaned stray tokens (editor buffer) - verified on-disk
    // Button Settings
    private static int buttonSize = 120;
    private static boolean roundedButtons = false;

    // Konfetti-Partikel
    private static final int CONFETTI_DURATION_MS = 5000; // gewünschte Dauer in ms
    private static final int CONFETTI_TIMER_DELAY_MS = 40; // Timer-Tick in ms (~25 FPS)
    private static final int CELEBRATION_DURATION_MS = 15000; // 15 Sekunden für den großen Jubel

    private static class Confetti {
        double x, y;
        double vx, vy;
        Color color;
        int life;
        int maxLife;
        int size;

        Confetti(double x, double y) {
            this.x = x;
            this.y = y;
            this.vx = (Math.random() - 0.5) * 30; // noch stärkere seitliche Geschwindigkeit
            this.vy = -24 - Math.random() * 24; // deutlich höherer Aufschub
            int[] colors = { 0xFF6B6B, 0x4ECDC4, 0xFFE66D, 0xFF8A65, 0xAE73DC, 0xFF1493, 0x00CED1 };
            this.color = new Color(colors[(int) (Math.random() * colors.length)]);
            int baseTicks = CONFETTI_DURATION_MS / CONFETTI_TIMER_DELAY_MS;
            int variance = (int) (Math.random() * 40) - 20; // +/- 20 ticks Variation
            this.maxLife = Math.max(10, baseTicks + variance);
            this.life = this.maxLife; // verbleibende Lebenszeit
            this.size = 18 + (int) (Math.random() * 14); // deutlich größere Partikel
        }

        // Overloaded constructor for custom-life/size confetti (used for large
        // celebration)
        Confetti(double x, double y, int customMaxLife, int customSize, double vxMultiplier, double vyBase) {
            this.x = x;
            this.y = y;
            this.vx = (Math.random() - 0.5) * vxMultiplier;
            this.vy = -(Math.random() * vyBase); // start with slight upward/neutral burst
            int[] colors = { 0xFF6B6B, 0x4ECDC4, 0xFFE66D, 0xFF8A65, 0xAE73DC, 0xFF1493, 0x00CED1 };
            this.color = new Color(colors[(int) (Math.random() * colors.length)]);
            this.maxLife = Math.max(10, customMaxLife);
            this.life = this.maxLife;
            this.size = Math.max(4, customSize);
        }

        void update() {
            x += vx;
            y += vy;
            vy += 0.12; // leichte Gravitation, damit die Partikel länger schweben
            life -= 1; // langsameres Ausblenden -> länger sichtbar
        }

        boolean isAlive() {
            return life > 0;
        }

        void draw(Graphics2D g) {
            double ratio = Math.max(0.0, Math.min(1.0, life / (double) maxLife));
            int alpha = (int) (255 * ratio);
            alpha = Math.min(255, Math.max(0, alpha));
            g.setColor(new Color(color.getRed(), color.getGreen(), color.getBlue(), alpha));
            g.fillOval((int) x, (int) y, size, size);
        }
    }

    private static java.util.List<Confetti> confetti = new java.util.ArrayList<>();

    // Firework + Spark classes for celebration
    private static class Spark {
        double x, y, vx, vy;
        int life, maxLife;
        Color color;

        Spark(double x, double y, double vx, double vy, int life, Color color) {
            this.x = x;
            this.y = y;
            this.vx = vx;
            this.vy = vy;
            this.maxLife = life;
            this.life = life;
            this.color = color;
        }

        void update() {
            x += vx;
            y += vy;
            vy += 0.12; // gravity
            // air drag
            vx *= 0.995;
            vy *= 0.998;
            life--;
        }

        boolean isAlive() {
            return life > 0;
        }

        void draw(Graphics2D g) {
            double ratio = Math.max(0.0, Math.min(1.0, life / (double) maxLife));
            int alpha = (int) (255 * ratio);
            alpha = Math.min(255, Math.max(0, alpha));
            g.setColor(new Color(color.getRed(), color.getGreen(), color.getBlue(), alpha));
            int s = Math.max(2, (int) (4 * ratio));
            g.fillOval((int) x, (int) y, s, s);
        }
    }

    private static class Firework {
        double x, y;
        double vy;
        Color color;
        boolean exploded = false;
        java.util.List<Spark> sparks = new java.util.ArrayList<>();

        Firework(double startX, double startY) {
            this.x = startX;
            this.y = startY;
            this.vy = -(8 + Math.random() * 6);
            int[] colors = { 0xFF6B6B, 0x4ECDC4, 0xFFE66D, 0xFF8A65, 0xAE73DC, 0xFF1493, 0x00CED1 };
            this.color = new Color(colors[(int) (Math.random() * colors.length)]);
        }

        void update() {
            if (!exploded) {
                y += vy;
                vy += 0.18; // gravity slowing ascent
                if (vy >= 0) {
                    explode();
                }
            } else {
                for (int i = sparks.size() - 1; i >= 0; i--) {
                    Spark s = sparks.get(i);
                    s.update();
                    if (!s.isAlive())
                        sparks.remove(i);
                }
            }
        }

        boolean isFinished() {
            return exploded && sparks.isEmpty();
        }

        void explode() {
            exploded = true;
            int count = 18 + (int) (Math.random() * 36);
            double speedBase = 2.5 + Math.random() * 3.5;
            for (int i = 0; i < count; i++) {
                double angle = Math.random() * Math.PI * 2;
                double speed = speedBase * (0.6 + Math.random() * 1.4);
                double vx = Math.cos(angle) * speed;
                double vy = Math.sin(angle) * speed - 1.0; // slight upward bias
                int life = 30 + (int) (Math.random() * 60);
                int rr = color.getRed() + (int) (Math.random() * 40 - 20);
                int gg = color.getGreen() + (int) (Math.random() * 40 - 20);
                int bb = color.getBlue() + (int) (Math.random() * 40 - 20);
                rr = Math.max(0, Math.min(255, rr));
                gg = Math.max(0, Math.min(255, gg));
                bb = Math.max(0, Math.min(255, bb));
                Color c = new Color(rr, gg, bb);
                sparks.add(new Spark(x, y, vx, vy, life, c));
            }
        }

        void draw(Graphics2D g) {
            if (!exploded) {
                g.setColor(color);
                g.fillOval((int) x - 3, (int) y - 3, 6, 6);
            } else {
                for (Spark s : sparks)
                    s.draw(g);
            }
        }
    }

    // fireworks list used for celebration
    private static java.util.List<Firework> fireworks = new java.util.ArrayList<>();

    private static class GameResult {
        String message;
        String status; // "win", "lose", "draw"
        String computerChoice;

        GameResult(String message, String status, String computerChoice) {
            this.message = message;
            this.status = status;
            this.computerChoice = computerChoice;
        }
    }

    private static ImageIcon loadImage(String choice) {
        String[] possiblePaths = {
                "images" + File.separator + choice + ".png",
                ".." + File.separator + "images" + File.separator + choice + ".png",
                new File(".").getAbsoluteFile().getParentFile().getAbsolutePath() + File.separator + "images"
                        + File.separator + choice + ".png"
        };

        for (String path : possiblePaths) {
            File file = new File(path);
            if (file.exists()) {
                ImageIcon icon = new ImageIcon(file.getAbsolutePath());
                // Skaliere basierend auf buttonSize
                int size = (int) (buttonSize * 0.85);
                return new ImageIcon(icon.getImage().getScaledInstance(size, size, Image.SCALE_SMOOTH));
            }
        }
        return null;
    }

    private static String getChoiceName(String choice) {
        switch (choice.toLowerCase()) {
            case "stein":
                return "Stein";
            case "papier":
                return "Papier";
            case "schere":
                return "Schere";
            default:
                return choice;
        }
    }

    private static GameResult spiele(String playerChoice) {
        String[] options = { "stein", "papier", "schere" };
        String computerChoice = options[(int) (Math.random() * 3)];

        if (playerChoice.equals(computerChoice))
            return new GameResult("Unentschieden!\nDu: " + playerChoice + " vs Computer: " + computerChoice, "draw",
                    computerChoice);

        boolean win = (playerChoice.equals("stein") && computerChoice.equals("schere")) ||
                (playerChoice.equals("papier") && computerChoice.equals("stein")) ||
                (playerChoice.equals("schere") && computerChoice.equals("papier"));

        String resultText = win ? "GEWONNEN!" : "VERLOREN!";
        return win
                ? new GameResult(resultText + "\nDu: " + playerChoice + " vs Computer: " + computerChoice, "win",
                        computerChoice)
                : new GameResult(resultText + "\nDu: " + playerChoice + " vs Computer: " + computerChoice, "lose",
                        computerChoice);
    }

    private static class EmojiPanel extends JPanel {
        private Timer konfettiTimer = null;
        private int konfettiRemainingTicks = 0;
        private boolean celebrationMode = false;
        private java.util.List<Firework> panelFireworks = new java.util.ArrayList<>();
        private JComponent gifOverlay = null;
        private Timer gifRemoveTimer = null;
        private String status = "";
        private String playerChoice = "";
        private String computerChoice = "";
        // animation settings
        private int battleFrame = 0;
        private Timer battleTimer;
        public boolean showResult = false;
        private final int TOTAL_FRAMES = 60; // smooth ~60 frames
        private final int TIMER_DELAY_MS = 16; // ~60 FPS
        private ImageIcon playerImgIcon = null;
        private ImageIcon computerImgIcon = null;

        public EmojiPanel() {
            setPreferredSize(new Dimension(300, 200));
            setBackground(new Color(10, 10, 10));
        }

        public void setBattle(String player, String computer) {
            playerChoice = player;
            computerChoice = computer;
            battleFrame = 0;
            showResult = false;
            status = "";

            if (battleTimer != null) {
                battleTimer.stop();
            }

            battleFrame = 0;
            // preload shake.png for animation phase
            playerImgIcon = loadImage("shake");
            computerImgIcon = loadImage("shake");

            battleTimer = new Timer(TIMER_DELAY_MS, e -> {
                battleFrame++;
                if (battleFrame >= TOTAL_FRAMES) {
                    battleTimer.stop();
                    showResult = true;
                    battleFrame = TOTAL_FRAMES;
                    // Load actual choice images for result display
                    playerImgIcon = loadImage(playerChoice);
                    computerImgIcon = loadImage(computerChoice);
                }
                repaint();
            });
            battleTimer.start();
        }

        public void setResult(String resultStatus) {
            status = resultStatus;
            // Only update status for this round; do not trigger confetti/fireworks here.
            // Full-window celebration is handled by `startCelebration()` which is
            // called when the overall win condition is reached.
            repaint();
        }

        // Start a full-window celebration confetti + fireworks for
        // CELEBRATION_DURATION_MS
        public void startCelebration() {
            if (konfettiTimer != null && konfettiTimer.isRunning()) {
                konfettiTimer.stop();
                konfettiTimer = null;
            }

            confetti.clear();
            panelFireworks.clear();
            celebrationMode = true;

            int ticks = Math.max(1, CELEBRATION_DURATION_MS / CONFETTI_TIMER_DELAY_MS);
            konfettiRemainingTicks = ticks;

            // spawn many particles across the whole panel
            int count = Math.min(1200, Math.max(500, (getWidth() * getHeight()) / 800));
            for (int i = 0; i < count; i++) {
                double startX = Math.random() * getWidth();
                double startY = Math.random() * (getHeight() * 0.6); // mostly top area
                int customSize = 20 + (int) (Math.random() * 30);
                int customLife = ticks + (int) (Math.random() * 40) - 20;
                Confetti c = new Confetti(startX, startY, customLife, customSize, 60.0, 40.0);
                confetti.add(c);
            }

            // Immediately spawn a visible set of fireworks so the user notices rockets
            int initialRockets = Math.max(6, Math.min(16, getWidth() / 80));
            for (int r = 0; r < initialRockets; r++) {
                double rx = Math.random() * Math.max(1, getWidth());
                double ry = getHeight() * (0.9); // start very near bottom
                panelFireworks.add(new Firework(rx, ry));
            }

            konfettiTimer = new Timer(CONFETTI_TIMER_DELAY_MS, ev -> {
                // Update confetti particles
                for (int i = confetti.size() - 1; i >= 0; i--) {
                    Confetti c = confetti.get(i);
                    c.update();
                    if (!c.isAlive()) {
                        confetti.remove(i);
                    }
                }

                // Occasionally spawn large fireworks during celebration (higher rate)
                if (celebrationMode && Math.random() < 0.25) {
                    double fx = Math.random() * Math.max(1, getWidth());
                    // start rockets near the bottom so they fly up visibly
                    double fy = getHeight() * (0.85 + Math.random() * 0.12);
                    panelFireworks.add(new Firework(fx, fy));
                }

                // Update fireworks
                for (int i = panelFireworks.size() - 1; i >= 0; i--) {
                    Firework f = panelFireworks.get(i);
                    f.update();
                    if (f.isFinished())
                        panelFireworks.remove(i);
                }

                repaint();

                konfettiRemainingTicks--;
                if (konfettiRemainingTicks <= 0) {
                    // stop celebration
                    konfettiTimer.stop();
                    celebrationMode = false;
                    confetti.clear();
                    panelFireworks.clear();
                    repaint();
                }
            });
            konfettiTimer.setRepeats(true);
            konfettiTimer.start();

            // Try to show the rendered GIF as a full-window overlay inside the same window
            try {
                File gifFile = new File("celebration.gif");
                if (gifFile.exists()) {
                    ImageIcon rawIcon = new ImageIcon(gifFile.getAbsolutePath());
                    // scale to panel size
                    Image scaled = rawIcon.getImage().getScaledInstance(getWidth(), getHeight(), Image.SCALE_SMOOTH);
                    ImageIcon icon = new ImageIcon(scaled);

                    JLabel gifLabel = new JLabel(icon);
                    gifLabel.setOpaque(false);
                    gifLabel.setBounds(0, 0, getWidth(), getHeight());

                    // add to layered pane so it appears above everything in the frame
                    JRootPane root = SwingUtilities.getRootPane(this);
                    if (root != null) {
                        JLayeredPane layered = root.getLayeredPane();
                        layered.add(gifLabel, JLayeredPane.POPUP_LAYER);
                        layered.revalidate();
                        layered.repaint();
                        gifOverlay = gifLabel;

                        // schedule removal after celebration duration
                        if (gifRemoveTimer != null && gifRemoveTimer.isRunning())
                            gifRemoveTimer.stop();
                        gifRemoveTimer = new Timer(CELEBRATION_DURATION_MS, e -> {
                            try {
                                layered.remove(gifLabel);
                                layered.revalidate();
                                layered.repaint();
                            } catch (Exception ex) {
                                // ignore
                            }
                        });
                        gifRemoveTimer.setRepeats(false);
                        gifRemoveTimer.start();
                    }
                }
            } catch (Throwable ex) {
                // best-effort: don't crash if GIF can't be shown
            }
        }

        @Override
        protected void paintComponent(Graphics g) {
            super.paintComponent(g);
            Graphics2D g2 = (Graphics2D) g;
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

            int centerX = getWidth() / 2;
            int centerY = getHeight() / 2;

            // Battle animation: accelerating shake with PNGs → fade strengthen → result
            if (battleFrame > 0 && !showResult) {
                double t = Math.max(0.0, Math.min(1.0, battleFrame / (double) TOTAL_FRAMES));

                int leftX = centerX - 130;
                int rightX = centerX + 30;
                int baseY = centerY - 50;

                if (t < 0.75) {
                    double shakePhase = t * t * 6;
                    int baseAmp = 40;
                    int amp = (int) (baseAmp * (1.0 + t));
                    int shakeY = (int) (Math.sin(shakePhase * Math.PI) * amp);

                    if (playerImgIcon != null)
                        playerImgIcon.paintIcon(this, g2, leftX, baseY + shakeY);
                    if (computerImgIcon != null)
                        computerImgIcon.paintIcon(this, g2, rightX, baseY + shakeY);

                    g2.setStroke(new BasicStroke(3));
                    g2.setColor(new Color(220, 220, 220));
                    g2.drawLine(centerX, centerY - 40, centerX, centerY + 40);
                } else {
                    if (playerImgIcon != null)
                        playerImgIcon.paintIcon(this, g2, leftX, baseY);
                    if (computerImgIcon != null)
                        computerImgIcon.paintIcon(this, g2, rightX, baseY);
                }

                return;
            }

            // Result display
            if (showResult) {
                ImageIcon playerImg = loadImage(playerChoice);
                ImageIcon computerImg = loadImage(computerChoice);
                int imgSize = (int) (buttonSize * 0.85);
                int gap = 40;
                int leftX = centerX - imgSize - gap / 2;
                int rightX = centerX + gap / 2;
                if (playerImg != null) {
                    playerImg.paintIcon(this, g2, leftX, centerY - 50);
                }
                if (computerImg != null) {
                    computerImg.paintIcon(this, g2, rightX, centerY - 50);
                }

                g2.setFont(new Font("Arial", Font.BOLD, 36));
                FontMetrics fm = g2.getFontMetrics();

                if (status.equals("win")) {
                    g2.setColor(new Color(0, 200, 0));
                    String text = "GEWONNEN!";
                    int textWidth = fm.stringWidth(text);
                    g2.drawString(text, centerX - textWidth / 2, centerY - 75);

                    // draw confetti
                    for (Confetti c : confetti)
                        c.draw(g2);
                    // draw fireworks
                    for (Firework f : panelFireworks)
                        f.draw(g2);

                    return;
                } else if (status.equals("lose")) {
                    g2.setColor(new Color(255, 100, 100));
                    String text = "VERLOREN!";
                    int textWidth = fm.stringWidth(text);
                    g2.drawString(text, centerX - textWidth / 2, centerY - 75);
                } else {
                    g2.setColor(new Color(255, 200, 0));
                    String text = "UNENTSCHIEDEN!";
                    int textWidth = fm.stringWidth(text);
                    g2.drawString(text, centerX - textWidth / 2, centerY - 75);
                }
                return;
            }

            // Default state
            g2.setFont(new Font("Arial", Font.PLAIN, 80));
            g2.setColor(new Color(100, 100, 100));
            g2.drawString("\u2753", centerX - 30, centerY + 35);
        }
    }

    public static void main(String[] args) {
        try {
            SwingUtilities.invokeLater(() -> {
                try {
                    JFrame frame = new JFrame("Schere Stein Papier");
                    frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
                    frame.setBackground(new Color(10, 10, 10));

                    JPanel mainPanel = new JPanel();
                    mainPanel.setLayout(new BoxLayout(mainPanel, BoxLayout.Y_AXIS));
                    mainPanel.setBackground(new Color(10, 10, 10));

                    // Declare button panel and list before settings
                    JPanel buttonPanel = new JPanel();
                    java.util.List<JButton> buttonList = new java.util.ArrayList<>();

                    // Settings Panel
                    JPanel settingsPanel = new JPanel();
                    settingsPanel.setLayout(new FlowLayout(FlowLayout.LEFT, 15, 10));
                    settingsPanel.setBackground(new Color(20, 20, 20));
                    settingsPanel.setMaximumSize(new Dimension(Integer.MAX_VALUE, 50));

                    JLabel sizeLabel = new JLabel("Button Größe:");
                    sizeLabel.setForeground(Color.WHITE);
                    sizeLabel.setFont(new Font("Arial", Font.BOLD, 12));

                    JSpinner sizeSpinner = new JSpinner(new SpinnerNumberModel(120, 80, 200, 10));
                    sizeSpinner.setPreferredSize(new Dimension(60, 25));
                    sizeSpinner.addChangeListener(e -> {
                        buttonSize = (Integer) sizeSpinner.getValue();
                        // Update button sizes immediately
                        for (JButton btn : buttonList) {
                            btn.setPreferredSize(new Dimension(buttonSize, buttonSize));
                            btn.setMaximumSize(new Dimension(buttonSize, buttonSize));
                        }
                        buttonPanel.revalidate();
                        buttonPanel.repaint();
                    });

                    JLabel borderLabel = new JLabel("Rahmen:");
                    borderLabel.setForeground(Color.WHITE);
                    borderLabel.setFont(new Font("Arial", Font.BOLD, 12));

                    JCheckBox borderCheckbox = new JCheckBox("Mit Rahmen");
                    borderCheckbox.setBackground(new Color(20, 20, 20));
                    borderCheckbox.setForeground(Color.WHITE);
                    borderCheckbox.setSelected(false);
                    borderCheckbox.addActionListener(e -> {
                        roundedButtons = borderCheckbox.isSelected();
                        // Update button borders immediately
                        for (JButton btn : buttonList) {
                            if (borderCheckbox.isSelected()) {
                                btn.setBorder(BorderFactory.createRaisedBevelBorder());
                            } else {
                                btn.setBorder(BorderFactory.createEmptyBorder());
                            }
                        }
                        buttonPanel.repaint();
                    });

                    settingsPanel.add(sizeLabel);
                    settingsPanel.add(sizeSpinner);
                    settingsPanel.add(Box.createHorizontalStrut(20));
                    settingsPanel.add(borderLabel);
                    settingsPanel.add(borderCheckbox);

                    mainPanel.add(settingsPanel);
                    mainPanel.add(Box.createVerticalStrut(10));

                    // Top Panel: DU vs COMPUTER Score
                    JPanel scorePanel = new JPanel();
                    scorePanel.setLayout(new BoxLayout(scorePanel, BoxLayout.X_AXIS));
                    scorePanel.setBackground(new Color(10, 10, 10));
                    scorePanel.setPreferredSize(new Dimension(400, 80));
                    scorePanel.setMaximumSize(new Dimension(Integer.MAX_VALUE, 80));

                    JLabel playerLabel = new JLabel("DU");
                    playerLabel.setFont(new Font("Arial", Font.BOLD, 20));
                    playerLabel.setForeground(Color.WHITE);
                    playerLabel.setAlignmentX(Component.CENTER_ALIGNMENT);

                    JLabel playerEmoji = new JLabel("\u270A");
                    playerEmoji.setFont(new Font("Arial", Font.PLAIN, 40));
                    playerEmoji.setForeground(new Color(0, 150, 255));

                    JLabel playerScore = new JLabel("0");
                    playerScore.setFont(new Font("Arial", Font.BOLD, 48));
                    playerScore.setForeground(new Color(0, 150, 255)); // Blue

                    JLabel computerLabel = new JLabel("COMPUTER");
                    computerLabel.setFont(new Font("Arial", Font.BOLD, 20));
                    computerLabel.setForeground(Color.WHITE);

                    JLabel computerEmoji = new JLabel("\u270A");
                    computerEmoji.setFont(new Font("Arial", Font.PLAIN, 40));
                    computerEmoji.setForeground(new Color(255, 100, 100));

                    JLabel computerScore = new JLabel("0");
                    computerScore.setFont(new Font("Arial", Font.BOLD, 48));
                    computerScore.setForeground(new Color(255, 100, 100)); // Red

                    scorePanel.add(Box.createHorizontalStrut(30));
                    scorePanel.add(playerLabel);
                    scorePanel.add(Box.createHorizontalStrut(10));
                    scorePanel.add(playerEmoji);
                    scorePanel.add(Box.createHorizontalStrut(10));
                    scorePanel.add(playerScore);
                    scorePanel.add(Box.createHorizontalGlue());
                    scorePanel.add(computerScore);
                    scorePanel.add(Box.createHorizontalStrut(10));
                    scorePanel.add(computerEmoji);
                    scorePanel.add(Box.createHorizontalStrut(10));
                    scorePanel.add(computerLabel);
                    scorePanel.add(Box.createHorizontalStrut(30));

                    mainPanel.add(scorePanel);

                    // Animation Panel
                    EmojiPanel emojiPanel = new EmojiPanel();
                    emojiPanel.setAlignmentX(Component.CENTER_ALIGNMENT);
                    mainPanel.add(Box.createVerticalStrut(20));
                    mainPanel.add(emojiPanel);

                    // Instructions
                    JLabel instructions = new JLabel("Waehle deine Waffe!");
                    instructions.setFont(new Font("Arial", Font.BOLD, 24));
                    instructions.setAlignmentX(Component.CENTER_ALIGNMENT);
                    instructions.setForeground(Color.WHITE);

                    mainPanel.add(Box.createVerticalStrut(20));
                    mainPanel.add(instructions);

                    // Choice Label
                    JLabel choiceLabel = new JLabel("Deine Wahl:");
                    choiceLabel.setFont(new Font("Arial", Font.BOLD, 20));
                    choiceLabel.setAlignmentX(Component.CENTER_ALIGNMENT);
                    choiceLabel.setForeground(Color.WHITE);

                    mainPanel.add(Box.createVerticalStrut(30));
                    mainPanel.add(choiceLabel);
                    mainPanel.add(Box.createVerticalStrut(20));

                    // Button Panel with 3 buttons
                    // Button Panel with 3 buttons
                    buttonPanel.setLayout(new FlowLayout(FlowLayout.CENTER, 20, 10));
                    buttonPanel.setBackground(new Color(10, 10, 10));

                    JButton stein = createRoundButton("", "stein");
                    JButton papier = createRoundButton("", "papier");
                    JButton schere = createRoundButton("", "schere");

                    buttonList.add(stein);
                    buttonList.add(papier);
                    buttonList.add(schere);

                    buttonPanel.add(stein);
                    buttonPanel.add(papier);
                    buttonPanel.add(schere);

                    mainPanel.add(buttonPanel);

                    // Bottom panel with points and reset
                    JPanel bottomPanel = new JPanel();
                    bottomPanel.setLayout(new BoxLayout(bottomPanel, BoxLayout.X_AXIS));
                    bottomPanel.setBackground(new Color(10, 10, 10));

                    JLabel pointsLabel = new JLabel("Siege bis zum Gewinn: ");
                    pointsLabel.setFont(new Font("Arial", Font.BOLD, 16));
                    pointsLabel.setForeground(Color.WHITE);

                    JSpinner winsSpinner = new JSpinner(new SpinnerNumberModel(3, 1, 100, 1));
                    winsSpinner.setFont(new Font("Arial", Font.BOLD, 14));
                    winsSpinner.setPreferredSize(new Dimension(50, 30));
                    winsSpinner.setMaximumSize(new Dimension(50, 30));

                    JLabel winsCounter = new JLabel("0 / 3");
                    winsCounter.setFont(new Font("Arial", Font.BOLD, 16));
                    winsCounter.setForeground(new Color(0, 200, 100));

                    JButton reset = new JButton("Reset");
                    reset.setFont(new Font("Arial", Font.BOLD, 14));
                    reset.setForeground(Color.WHITE);
                    reset.setBackground(new Color(70, 70, 70));
                    reset.setFocusPainted(false);
                    reset.setBorderPainted(true);
                    reset.setOpaque(true);
                    reset.setPreferredSize(new Dimension(100, 40));
                    reset.setMaximumSize(new Dimension(100, 40));
                    reset.setCursor(new Cursor(Cursor.HAND_CURSOR));

                    bottomPanel.add(Box.createHorizontalGlue());
                    bottomPanel.add(pointsLabel);
                    bottomPanel.add(winsSpinner);
                    bottomPanel.add(Box.createHorizontalStrut(15));
                    bottomPanel.add(winsCounter);
                    bottomPanel.add(Box.createHorizontalStrut(30));
                    bottomPanel.add(reset);
                    bottomPanel.add(Box.createHorizontalGlue());

                    mainPanel.add(Box.createVerticalGlue());
                    mainPanel.add(bottomPanel);
                    mainPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 20, 10));

                    ActionListener listener = e -> {
                        JButton btn = (JButton) e.getSource();
                        String cmd = btn.getName().toLowerCase();

                        GameResult gameResult = spiele(cmd);
                        String computerChoice = gameResult.computerChoice;

                        // Start battle animation
                        emojiPanel.setBattle(cmd, computerChoice);

                        // Update result after animation completes (1500ms)
                        Timer resultTimer = new Timer(1500, evt -> {
                            boolean playerWon = gameResult.status.equals("win");

                            // Update scores
                            int playerScoreVal = Integer.parseInt(playerScore.getText());
                            int computerScoreVal = Integer.parseInt(computerScore.getText());

                            if (playerWon) {
                                playerScore.setText(String.valueOf(playerScoreVal + 1));
                            } else if (gameResult.status.equals("lose")) {
                                computerScore.setText(String.valueOf(computerScoreVal + 1));
                            }

                            emojiPanel.setResult(gameResult.status);
                            emojiPanel.showResult = true;
                            emojiPanel.repaint();

                            // Check win condition
                            int targetWins = (int) winsSpinner.getValue();
                            playerScoreVal = Integer.parseInt(playerScore.getText());
                            computerScoreVal = Integer.parseInt(computerScore.getText());

                            if (playerScoreVal >= targetWins) {
                                instructions.setText("DU HAST GEWONNEN!!!");
                                instructions.setForeground(new Color(0, 200, 0));
                                stein.setEnabled(false);
                                papier.setEnabled(false);
                                schere.setEnabled(false);
                                // Start a full-window celebration for the overall win
                                emojiPanel.startCelebration();
                            } else if (computerScoreVal >= targetWins) {
                                instructions.setText("DU HAST VERLOREN!");
                                instructions.setForeground(new Color(255, 100, 100));
                                stein.setEnabled(false);
                                papier.setEnabled(false);
                                schere.setEnabled(false);
                            }

                            int currentWins = Integer.parseInt(winsCounter.getText().split(" / ")[0]);
                            winsCounter.setText(Math.max(playerScoreVal, computerScoreVal) + " / " + targetWins);
                        });
                        resultTimer.setRepeats(false);
                        resultTimer.start();
                    };

                    stein.addActionListener(listener);
                    papier.addActionListener(listener);
                    schere.addActionListener(listener);

                    reset.addActionListener(e -> {
                        playerScore.setText("0");
                        computerScore.setText("0");
                        int targetWins = (int) winsSpinner.getValue();
                        winsCounter.setText("0 / " + targetWins);
                        instructions.setText("Waehle deine Waffe!");
                        instructions.setForeground(Color.WHITE);
                        stein.setEnabled(true);
                        papier.setEnabled(true);
                        schere.setEnabled(true);
                    });

                    winsSpinner.addChangeListener(e -> {
                        int targetWins = (int) winsSpinner.getValue();
                        int currentWins = Integer.parseInt(winsCounter.getText().split(" / ")[0]);
                        winsCounter.setText(currentWins + " / " + targetWins);
                    });

                    frame.getContentPane().add(mainPanel);
                    frame.setSize(700, 750);
                    frame.setLocationRelativeTo(null);
                    frame.setVisible(true);
                } catch (Exception ex) {
                    System.err.println("Fehler beim Erstellen des GUIs: " + ex.getMessage());
                    ex.printStackTrace();
                }
            });
        } catch (Exception ex) {
            System.err.println("Kritischer Fehler: " + ex.getMessage());
            ex.printStackTrace();
        }
    }

    private static JButton createRoundButton(String emoji, String name) {
        JButton button = new JButton() {
            @Override
            protected void paintComponent(Graphics g) {
                super.paintComponent(g);
                Graphics2D g2 = (Graphics2D) g;
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

                ImageIcon img = loadImage(name);
                if (img != null) {
                    img.paintIcon(this, g2, 10, 10);
                }
            }
        };
        button.setName(name);
        button.setForeground(Color.BLACK);
        button.setBackground(new Color(70, 70, 70));
        button.setFocusPainted(false);
        button.setBorderPainted(true);
        button.setOpaque(true);
        button.setPreferredSize(new Dimension(buttonSize, buttonSize));
        button.setMaximumSize(new Dimension(buttonSize, buttonSize));
        button.setCursor(new Cursor(Cursor.HAND_CURSOR));

        // Standardmäßig ohne Rahmen
        button.setBorder(BorderFactory.createEmptyBorder());

        button.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseEntered(java.awt.event.MouseEvent evt) {
                button.setBackground(new Color(100, 100, 100));
            }

            public void mouseExited(java.awt.event.MouseEvent evt) {
                button.setBackground(new Color(70, 70, 70));
            }
        });
        return button;
    }
}
