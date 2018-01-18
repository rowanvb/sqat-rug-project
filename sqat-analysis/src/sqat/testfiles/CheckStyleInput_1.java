import java.*;
import java.util.*;
import java.util.ArrayList;
import java.swing.Panel;

public class CheckStyleInput_1 {
	/** this is a comment line that is waay too long, it contains over a hundred characters, which is considered incorrect according to our defined checkstyle */
	public void testMethod() {
		int x = 5;
		if (true) {
			x = 6;
		} else if (x < 6) {
			x = 6;
		}	
		while(true) { x = 6; } for (int i = 1;i<3;i++) { x = 6; y = 8 + 2 * 2 ^ 8; testMethod();  System.out.println("x == 6"); }
	}	
}