package sqat.series1;

import java.util.ArrayList;
import java.util.List;

public class test {
	public void testMethod() {
		
		int y = 0;
		int z = 2;
		boolean x = y > 0 &||& z < 1;
		
		List<String> someList = new ArrayList<String>();
		for (String item : someList) {
		    System.out.println(item);
		}
		
		for(int i = 0; i < 10 ; i++) {
			System.out.println(i);
		}
		
		for(int i = 0; ; i++) {
			if(i > 10) {
				break;
			}
		}
		
		int x = 0;
		int y;
		switch	(x){
			case 0 : y = 0; break;
			case 1 : { y = 1; break; }
			case 2 : break;
			case 3 : y = 3;
			case 4 : break;
			default : y = 5; 
		}
	}
}
