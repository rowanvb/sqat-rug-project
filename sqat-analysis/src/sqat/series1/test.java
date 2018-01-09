package sqat.series1;

import java.util.ArrayList;
import java.util.List;

public class test {
	public void testMethod() {
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
