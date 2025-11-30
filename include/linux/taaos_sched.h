/*
 * TaaOS Scheduler Optimizations
 * Custom scheduler tweaks for AI workloads
 */

#ifndef _LINUX_TAAOS_SCHED_H
#define _LINUX_TAAOS_SCHED_H

/* TaaOS-specific scheduler constants */
#define TAAOS_AI_PRIORITY_BOOST 5
#define TAAOS_NEURAL_ENGINE_NICE -10
#define TAAOS_BRAIN_NICE -5

/* Priority boost for AI processes */
static inline int taaos_ai_priority_boost(struct task_struct *p)
{
	if (strstr(p->comm, "taaos") || 
	    strstr(p->comm, "ollama") ||
	    strstr(p->comm, "python")) {
		return TAAOS_AI_PRIORITY_BOOST;
	}
	return 0;
}

#endif /* _LINUX_TAAOS_SCHED_H */
