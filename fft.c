
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
//#define TRSIZ 4
#define SWAP(a,b) tempr=(a); (a)=(b); (b)=tempr


/*
 * Implementation of FFT done by http://www.guitarscience.net/papers/fftalg.pdf
 * Simple Fast Fourier Transformation Algorithms in C
 */

int* fft_func(int* data_input,int size) {
    float wtemp, wr, wpr, wpi, wi, theta;
    float tempr, tempi;
    int N = size;
   // printf("\n%d",N);
    int i = 0, j = 0, n = 0, k = 0, m = 0, isign = -1, istep, mmax;
	float data1[2*N];
	for (unsigned i=0;i<N*2;i=i+2){
  		data1[i]=0;
		data1[i+1]=data_input[i/2];
	}
        for(unsigned i=0;i<N*2;i++){
           // printf("\n%f",data1[i]);
        }
        
    //float data1[2 * TRSIZ]= {1, 0, 0, 0, 1, 0, 0, 0};
    float *data;
    data = &data1[0] - 1;
    n = N * 2;
    j = 1;
    int amp[N];
    // do the bit-reversal
    for (i = 1; i < n; i += 2) {
        if (j > i) {
            SWAP(data[j], data[i]);
            SWAP(data[j + 1], data[i + 1]);
        }
        m = n >> 1;
        while (m >= 2 && j > m) {
            j -= m;
            m >>= 1;
        }
        j += m;
    }
    // calculate the FFT
    mmax = 2;
    while (n > mmax) {
        istep = mmax << 1;
        theta = isign * (6.28318530717959 / mmax);
        wtemp = sin(0.5 * theta);
        wpr = -2.0 * wtemp*wtemp;
        wpi = sin(theta);
        wr = 1.0;
        wi = 0.0;
        for (m = 1; m < mmax; m += 2) {
            for (i = m; i <= n; i += istep) {
                j = i + mmax;
                tempr = wr * data[j] - wi * data[j + 1];
                tempi = wr * data[j + 1] + wi * data[j];
                data[j] = data[i] - tempr;
                data[j + 1] = data[i + 1] - tempi;
                data[i] = data[i] + tempr;
                data[i + 1] = data[i + 1] + tempi;
            }
            
            wtemp = wr;
            wr += wtemp * wpr - wi*wpi;
            wi += wtemp * wpi + wi*wpr;
        }
        mmax = istep;
    }

    unsigned x=0;
    for (k = 0; k < 2 * N; k += 2){
       int temp=round(sqrt(data[k+1]*data[k+1]+data[k+2]*data[k+2]));
       printf("\n%f,%f",data[k+1],data[k+2]);
		amp[x]=temp;
 //printf("\n%d",temp);
        x=x+1;
    }
    for (unsigned y=0;y<N;y++){
       //printf("\n%d",amp[y]);
    }
    return amp;
} // end of dittt()

