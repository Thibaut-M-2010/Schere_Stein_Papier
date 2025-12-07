import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;

public class CreateImages {
    public static void main(String[] args) throws Exception {
        // Erstelle images-Verzeichnis
        new File("images").mkdirs();

        // Stein
        createSteinImage();
        // Papier
        createPapierImage();
        // Schere
        createSchereImage();

        System.out.println("PNG-Dateien erstellt!");
    }

    static void createSteinImage() throws Exception {
        BufferedImage img = new BufferedImage(200, 200, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2 = img.createGraphics();
        g2.setColor(Color.WHITE);
        g2.fillRect(0, 0, 200, 200);
        g2.setColor(Color.BLACK);
        g2.setStroke(new BasicStroke(3));
        g2.drawOval(10, 10, 180, 180);
        g2.drawOval(70, 60, 60, 60);
        g2.setStroke(new BasicStroke(2));
        g2.drawLine(85, 80, 80, 50);
        ImageIO.write(img, "png", new File("images/stein.png"));
    }

    static void createPapierImage() throws Exception {
        BufferedImage img = new BufferedImage(200, 200, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2 = img.createGraphics();
        g2.setColor(Color.WHITE);
        g2.fillRect(0, 0, 200, 200);
        g2.setColor(Color.BLACK);
        g2.setStroke(new BasicStroke(3));
        g2.drawOval(10, 10, 180, 180);
        g2.drawOval(75, 85, 50, 50);
        g2.setStroke(new BasicStroke(2));
        for (int i = 0; i < 4; i++) {
            int x = 85 + i * 10;
            g2.drawLine(x, 85, x, 40);
        }
        g2.drawLine(70, 100, 50, 130);
        ImageIO.write(img, "png", new File("images/papier.png"));
    }

    static void createSchereImage() throws Exception {
        BufferedImage img = new BufferedImage(200, 200, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2 = img.createGraphics();
        g2.setColor(Color.WHITE);
        g2.fillRect(0, 0, 200, 200);
        g2.setColor(Color.BLACK);
        g2.setStroke(new BasicStroke(3));
        g2.drawOval(10, 10, 180, 180);
        g2.setStroke(new BasicStroke(3));
        g2.drawLine(100, 90, 75, 140);
        g2.drawLine(100, 90, 125, 140);
        g2.setStroke(new BasicStroke(2));
        g2.drawLine(95, 110, 85, 95);
        ImageIO.write(img, "png", new File("images/schere.png"));
    }
}
