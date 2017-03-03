#include <cmath>
#include <iostream>
#include "TFile.h"
#include "TTree.h"
#include "TRandom.h"
#include <fstream>

using namespace std;
const double Kaon_Mass = 497.65;
const double Pion_Mass = 134.98;
const double Pion_Mass2 = 139.58;
int Events_number = 500000000;




int main()
{
        TRandom r(0);
        // mass 
        double daughtermass[3];
        double sumofdaughtermass = 0.0;
        for (int index = 0;index <3; index++){
                daughtermass[index] = Pion_Mass;
                sumofdaughtermass += daughtermass[index];
        }

        // root tree
        TFile *outfile = new TFile("perturbed.root","RECREATE");
        TTree *tr = new TTree("tr","");
        double XY[2];
        tr->Branch("XY",XY,"XY[2]/D");
        // generate data        
        for (int index = 0;index <Events_number; index++){
                double rd1, rd2;
                double daughtermomentum[3];
                double momentummax = 0.0, momentumsum = 0.0;
                double energy;
                double R, theta, Xd, Yd, T1, T2;
                // Unweighted data
                do
                {
                        rd1 = r.Uniform(0,1);
                        rd2 = r.Uniform(0,1);
                        momentummax = 0.0;
                        momentumsum = 0.0;
                        R = sqrt(200-sqrt(200*200-1584*rd1));
                        theta = rd2*2*3.14159;
                        Xd = R*cos(theta);
                        Yd = R*sin(theta);
                        T1 = 30.9033-16.9521*Xd+9.78729*Yd;
                        T2 = 30.9033+16.9521*Xd+9.78729*Yd;
                        if ((T1<0)||(T2<0)||(T1+T2>92.71)){
                                momentummax = 0.1;
                                continue;
                        }
                        energy = T1;
                        daughtermomentum[0] = sqrt(energy*energy + 2.0*energy*daughtermass[0]);
                        if ( daughtermomentum[0] > momentummax)
                        {
                                        momentummax =  daughtermomentum[0];
                        }
                        momentumsum  +=  daughtermomentum[0];

                        energy = T2;
                        daughtermomentum[1] = sqrt(energy*energy + 2.0*energy* daughtermass[1]);
                        if ( daughtermomentum[1] >momentummax )
                        {
                                        momentummax =  daughtermomentum[1];
                                        }
                                        momentumsum  +=  daughtermomentum[1];

                        energy = 92.71-T2-T1;
                        daughtermomentum[2] = sqrt(energy*energy + 2.0*energy* daughtermass[2]);
                        if ( daughtermomentum[2] >momentummax )
                        {
                                momentummax =  daughtermomentum[2];
                        }
                        momentumsum  +=  daughtermomentum[2];
                } while (momentummax > momentumsum - momentummax );

// Mass data      
XY[0] = Xd;
XY[1] = Yd;
tr->Fill();
}

outfile->Write();
outfile->Close();
return 0;
}


