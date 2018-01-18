public class CheckStyleInput_2 {
	public void testMethod2() {
		int x = 0;
		while(true) 
			for (int i = 1; i<100; i--) 
				if (i < 2) 				
					x = x + i; 
				else 
					System.out.println("i >= 2");	
	}
}